require "test/unit"

class TemplateTest < Test::Unit::TestCase
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
end
