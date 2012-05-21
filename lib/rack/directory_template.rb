require "erb"
require "etc"
require "rack/accept"
require "rack/utils"
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
      @depth  = options[:depth].to_i
      # TODO: rename to @recursive?
      @depth  = 1 if @depth < 1
      @accept = [ options[:accept] || TYPES.values ].flatten.compact
      @templates = create_templates(options[:templates])
    end

    def call(env)
      path = realpath(env)

      if !::File.exists?(path)
        not_found
      elsif !::File.readable?(path)
        forbidden
      elsif ::File.directory?(path)
        process_directory(env)
      else
        @app.call(env)
      end
    end

    protected
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

    def process_directory(env)
      type = Rack::Accept::Request.new(env).best_media_type(TYPES.keys)
      return not_acceptable unless @accept.include?(TYPES[type])

      realpath = realpath(env)
      reqpath  = ::File.join("/", env["SCRIPT_NAME"].to_s, env["PATH_INFO"].to_s)
      # ex
      listing  = create_listing(realpath, reqpath)

      t = @templates[TYPES[type]]
      response = t.respond_to?(:call) ? t.call(listing) : t.send(TYPES[type], listing)

      reply(200, response, "Content-Type" => type)
    end

    def create_listing(realpath, reqpath, curdepth = 1)
      parent = stat(realpath)
      return {} unless parent

      parent[:url]  = reqpath
      parent[:name] = reqpath.split("/")[-1] || "/"

      listing = []
      dir(realpath) do |path, basename|
        entry = stat(path)
        next unless entry

        url = reqpath.dup
        url << "/" unless url.end_with?("/")
        url << Rack::Utils.escape_path(basename)

        entry[:url] = url
        entry[:name] = basename

        # TODO: true should mean no limit
        if entry[:type] == "directory" && curdepth < @depth
          entry[:files] = create_listing(path, url, curdepth + 1)
        end

        listing << entry
      end

      parent[:files] = listing
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
    rescue # nothing
    end

    def dir(root)
      Dir.foreach(root) do |file|
        next if file =~ %r{\A\.\.?\z}
        path = ::File.join(root, file)
        yield(path, file)
      end
    end

    def realpath(env)
      target = ::File.join("/", env["PATH_INFO"].to_s)
      # TODO: Uhhhh, CGI unescape here..?!
      target = ::File.expand_path(Rack::Utils.unescape(target), "/")
      ::File.join(@root, target)
    end

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
