require "rr"
require "tmpdir"
require "directory_template_test"
require "rack/directory_template/template_factory"

class TestResponseTypes < DirectoryTemplateTest
  Factory = Rack::DirectoryTemplate::TemplateFactory
 
  def setup
    @tmpdir  = Dir.mktmpdir
    @listing = create_listing(@tmpdir)
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  # https://github.com/btakita/rr/issues/35
  include RR::Adapters::TestUnit

  def app
    Rack::DirectoryTemplate.new @tmpdir
  end
  
  def test_text_html_response
    mock(Factory).html(@listing)
    req "/"
    assert_equal 200, last_response.status
  end

  def test_application_xml_response   
    mock(Factory).xml(@listing)
    req "/", "application/xml"
    assert_equal 200, last_response.status
  end

  def test_text_xml_response   
    mock(Factory).xml(@listing)
    req "/", "text/xml"
    assert_equal 200, last_response.status
  end

  def test_application_json_response   
    mock(Factory).json(@listing)
    req "/", "application/json"
    assert_equal 200, last_response.status
  end
  
  def test_text_javascript_response   
    mock(Factory).json(@listing)
    req "/", "text/javascript"
    assert_equal 200, last_response.status
  end

  def test_not_acceptable
    get "/", {}, "HTTP_ACCEPT" => "text/plain"
    assert_equal 406, last_response.status
  end

  def test_not_found
    req "/_not_there_"
    assert_equal 404, last_response.status
  end

  def test_forbidden    
    no_access = "#{@tmpdir}/nope"
    Dir.mkdir(no_access)
    File.chmod(0, no_access) # Win
    req "/nope"
    assert_equal 403, last_response.status
  end
end
