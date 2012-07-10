require "test_helper"

class TestUserTemplatesFromDirectory < Test::Unit::TestCase
  def setup
    @templates = Dir.mktmpdir    
    File.open("#{@templates}/html.erb", "w") { |f| f.write("html") }
    File.open("#{@templates}/something.xml.erb", "w") { |f| f.write("xml") }
  end

  def teardown 
    FileUtils.rm_rf(@templates)
  end

  def app
    Rack::DirectoryTemplate.new @templates, :templates => @templates
  end
  
  def test_xml_template_used
    req "/", "application/xml"
    assert_equal "xml", last_response.body 
  end

  def test_html_template_used
    req "/"
    assert_equal "html", last_response.body 
  end
end
