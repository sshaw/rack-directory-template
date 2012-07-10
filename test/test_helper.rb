require "rr"
require "tmpdir"
require "test/unit"
require "rack/utils"
require "rack/test"
require "rack/directory_template"
require "rack/directory_template/util"

class Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::TestUnit
  
  Factory = Rack::DirectoryTemplate::TemplateFactory

  protected
  def req(path, *options)
    params = Hash === options.last ? options.pop : {}  
    type = options.shift || "text/html"
    get path, params, "HTTP_ACCEPT" => type
  end

  def session(*options)
    app = Rack::DirectoryTemplate.new *options
    t = Rack::Test::Session.new(app)
    t.header("Accept", "text/html")
    t
  end

  def mktree(root, fs, url = "/")
    tree = { :files => [] }
    
    fs.each do |entry|
      if Hash === entry
        dir = entry.keys.first
        path = File.join(root, dir)
        Dir.mkdir(path)
        tree[:files] << mktree(path, entry.values.first, File.join(url, Rack::Utils.escape_path(dir)))
      else
        path = File.join(root, entry)
        File.open(path, "w") { |f| f.write(entry) }
        info = stat(path, File.join(url, Rack::Utils.escape_path(entry)))
        tree[:files] << info
      end
    end
  
    tree.merge!(stat(root, url))
    tree
  end
  
  def stat(path, url = "/")
    entry = Rack::DirectoryTemplate::Util.stat(path)
    entry[:url] = url
    entry[:name] = url == "/" ? url : File.basename(path) 
    entry
  end
end
