require "directory_template_test"

#class TestRecursion < DirectoryTemplateTest
#end

class TestAcceptOption < DirectoryTemplateTest
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  def app
    Rack::DirectoryTemplate.new @tmpdir, :accept => [:html, :xml]
  end
  
  def test_html_accepted
    req "/"
    assert last_response.body.start_with?("<html")
  end

  def test_xml_accepted
    req "/", "application/xml"
    assert last_response.body.start_with?("<?xml")
  end

  def test_json_not_accepted
    req "/", "application/json"
    assset_equal 206, last_response.status
  end
end
