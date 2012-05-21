require "fileutils"
require "test/unit"
require "rack/test"
require "rack/directory_template"

class DirectoryTemplateTest < Test::Unit::TestCase
  include Rack::Test::Methods

  protected 
  def req(path, type = "text/html", params = {})
    get path, params, "HTTP_ACCEPT" => type 
  end
    
  def create_listing(root)
    file  = "#{root}/fileA"
    File.open(file, "w") { |f| f.puts("data") }
    dstat = file_entry(root)
    dstat[:files] = [ file_entry(file, "/fileA") ]    
    dstat
  end

  def file_entry(path, url = "/")
    st = File.stat(path)
    entry = { :url => url, :name => File.basename(url) }
    [:size, :mode, :mtime, :atime, :ctime].each do |field|
      entry[field] = st.send(field)
    end
    entry[:type]  = st.ftype
    entry[:user]  = Etc.getpwuid(st.uid).name 
    entry[:group] = Etc.getgrgid(st.gid).name
    entry
  end
end
