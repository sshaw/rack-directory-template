require "directory_template_test"

class TestUserTemplatesFromHash < DirectoryTemplateTest 
  def setup
    @tmpdir = Dir.mktmpdir    
    File.open("#{@tmpdir}/json.template", "w") { |f| f.write("json") }
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  def app
    Rack::DirectoryTemplate.new @tmpdir, :templates => { 
      :json => "#{@tmpdir}/json.template",
      :html => lambda { |data| "html" } 
    }
  end
  
  def test_html_template_used
    req "/"
    assert_equal "html", last_response.body 
  end

  def test_json_template_used
    req "/", "application/json"
    assert_equal "json", last_response.body 
  end

  def test_default_xml_template_used
    req "/", "application/xml"
    assert last_response.body.start_with?("<?xml")
  end
end
