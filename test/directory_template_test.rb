require "rr"
require "etc"
require "tmpdir"
require "test/unit"
require "rack/utils"
require "rack/test"
require "rack/directory_template"

class DirectoryTemplateTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::RRMethods

  Factory = Rack::DirectoryTemplate::TemplateFactory

  protected
  def req(path, type = "text/html", params = {})
    get path, params, "HTTP_ACCEPT" => type
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
    entry = { 
      :url  => url, 
      :name => url == "/" ? url : File.basename(path) 
    }

    stat  = File.stat(path)    
    [:size, :mode, :mtime, :atime, :ctime].each do |field|
      entry[field] = stat.send(field)
    end
    
    entry[:type]  = stat.ftype
    entry[:user]  = Etc.getpwuid(stat.uid).name
    entry[:group] = Etc.getgrgid(stat.gid).name
    entry
  end
end
