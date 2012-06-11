require "erb"
require "etc"
require "rack"
require "rack/accept"
require "rack/directory_template/template_factory"

module Rack
  class DirectoryTemplate
    TYPES = { "text/html"        => :html,
              "application/json" => :json,
              "text/javascript"  => :json,  # some (e.g., Prototype) send this but will accept JSON
              "text/xml"         => :xml,
              "application/xml"  => :xml }

    TEMPLATES = TYPES.values.inject({}) { |t, format| t[format] = TemplateFactory; t }

    def initialize(root, options = {})
      raise ArgumentError, "root directory required" unless root

      @root = ::File.expand_path(root)
      raise ArgumentError, "not a directory #{@root}" unless ::File.directory?(@root)

      @app    = options[:app] || Rack::File.new(@root)
      @param  = options[:param]
      @depth  = options[:recurse] == false ? -1 : options[:recurse] 
      @depth  = @depth.to_i if @depth != true
      @accept = [ options[:accept] || TYPES.values ].flatten.compact
      @templates = create_templates(options[:templates])
    end

    def call(env)
      req  = Rack::Request.new(env)
      path = realpath(req)

      if !::File.exists?(path)
        not_found
      elsif !::File.readable?(path)
        forbidden
      elsif ::File.directory?(path)
        process_directory(req)
      else        
        pass(req)
      end
    end

    private
    def not_found
      reply(404, "Not Found\n")
    end

    def not_acceptable
      reply(406, "Not Acceptable\n")
    end

    def forbidden
      reply(403, "Forbidden\n")
    end

    def reply(code, message, headers = {})
      headers["Content-Type"] ||= "text/plain"
      headers["Content-Length"] = message ? message.bytesize.to_s : "0"  # >= 1.8.7
      message = [message] unless message.respond_to?(:each)
      [code, headers, message]
    end

    def process_directory(req)
      # Rack::Accept::Request is not a Rack::Request :(
      type = Rack::Accept::Request.new(req.env).best_media_type(TYPES.keys)
      return not_acceptable unless @accept.include?(TYPES[type])

      reqpath = reqpath(req)
      realpath = realpath(req)
      listing = create_listing(realpath, reqpath)

      t = @templates[TYPES[type]]
      response = t.respond_to?(:call) ? t.call(listing) : t.send(TYPES[type], listing)

      reply(200, response, "Content-Type" => type)
    rescue => e
      reply(500, "Error: #{e}\n")
    end
    
    def pass(req)
      if @param
        req.env["PATH_INFO"] = Rack::Utils.escape_path(req[@param]) 
      end
      @app.call(req.env)
    end

    def create_listing(realpath, reqpath, curdepth = 0)      
      parent = stat(realpath)
      parent[:url] = reqpath 
      parent[:name] = ::File.basename(reqpath)
      parent[:files] = []

      dir(realpath) do |path, basename|
        url = ::File.join(reqpath, Rack::Utils.escape_path(basename))

        if ::File.directory?(path) && (@depth == true || curdepth < @depth)
          entry = create_listing(path, url, curdepth + 1)
        else          
          entry = stat(path)
          entry[:url] = url
          entry[:name] = basename
        end

        parent[:files] << entry
      end

      parent
    end

    def stat(path)
      st = ::File.lstat(path)
      entry = {}
      [:size, :mode, :mtime, :atime, :ctime].each { |attr| entry[attr] = st.send(attr) }
      entry[:type]  = st.ftype
      #TODO: Win
      entry[:user]  = Etc.getpwuid(st.uid).name
      entry[:group] = Etc.getgrgid(st.gid).name
      entry
    end

    def dir(root)
      Dir.foreach(root) do |file|
        next if file =~ %r{^\.}
        path = ::File.join(root, file)
        yield(path, file)
      end
    end

    def reqpath(req)
      reqpath  = @param ? Rack::Utils::escape_path(req[@param]) : req.path
      reqpath ||= "/"
      reqpath
    end

    def realpath(req)
      target = @param ? req[@param] : Rack::Utils.unescape(req.path_info) 
      target ||= "/"
      target = ::File.expand_path(target, "/")
      ::File.join(@root, target)
    end

    # Maybe rangle this insanity into its own class
    def create_templates(config)
      check_class = lambda do |klass, m|
        unless klass.respond_to?(m)
          raise ArgumentError, "handler #{klass} does not have a method named '#{m}'"
        end
      end

      templates = case config
        when nil
          @accept.inject({}) do |cfg,name|
            unless t = TEMPLATES[name]
              raise ArgumentError, "no handler defined for #{name}"
            end
            cfg[name] = t
            cfg
          end
        when String
          unless ::File.directory?(config)
            raise ArgumentError, ":templates option '#{config}' is not a directory"
          end
          load_directory(config)
        when Hash
          config.select { |k,v| @accept.include?(k) }.inject({}) do |cfg, (name,t)|
            cfg[name] = case t
              when String
                load_file(t)
              when Class, Proc
                check_class.call(t,name) if t.is_a?(Class)
                t
              else
                raise ArgumentError, "invalid handler #{t} for type '#{name}'"
            end
            cfg
          end
        when Class
          @accept.inject({}) do |cfg,name|
            check_class.call(config,name)
            cfg[name] = config
            cfg
          end
      end

      templates = TEMPLATES.merge(templates)
      templates
    end

    def load_file(path)
      t = ErbTemplate.new(path)
      lambda { |data| t.render(data) }
    end

    def load_directory(root)
      templates = {}
      dir(root) do |path, basename|
        next unless ::File.file?(path)

        # name.ext OR name.format.ext (though the 2nd cannot [yet?] be used to load a handler)
        parts = basename.split(/\./)[-2..-1]
        type  = parts && !parts[0].empty? ? parts[0].to_sym : nil
        next if templates[type] || !@accept.include?(type)

        templates[type] = load_file(path)
      end
      templates
    end
  end

  class ErbTemplate
    include ERB::Util

    def initialize(path)
      @erb = ERB.new(::File.read(path))
    end

    def render(_listing)
      listing = _listing
      @erb.result(binding)
    end
  end
end
