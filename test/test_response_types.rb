require "test_helper"

class TestResponseTypes < Test::Unit::TestCase
  def setup
    @tmpdir  = Dir.mktmpdir
    @listing = mktree(@tmpdir, %w[A B])
    RR.reset
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  def app
    Rack::DirectoryTemplate.new @tmpdir
  end
  
  def test_text_html_response
    stub(Factory).html
    req "/"

    assert_equal 200, last_response.status
    assert_equal "text/html", last_response.content_type
    assert_received(Factory) { |s| s.html(@listing) }
  end

  def test_application_xml_response   
    stub(Factory).xml
    type = "application/xml"
    req "/", type

    assert_equal 200, last_response.status
    assert_equal type, last_response.content_type
    assert_received(Factory) { |s| s.xml(@listing) }
  end

  def test_text_xml_response   
    stub(Factory).xml
    type = "text/xml"
    req "/", type

    assert_equal 200, last_response.status
    assert_equal type, last_response.content_type
    assert_received(Factory) { |s| s.xml(@listing) }
  end

  def test_application_json_response   
    stub(Factory).json
    type = "application/json"
    req "/", type

    assert_equal 200, last_response.status
    assert_equal type, last_response.content_type
    assert_received(Factory) { |s| s.json(@listing) }
  end
  
  def test_text_javascript_response   
    stub(Factory).json
    type = "text/javascript"
    req "/", type
    assert_equal 200, last_response.status
    assert_equal type, last_response.content_type
    assert_received(Factory) { |s| s.json(@listing) }
  end

  def test_not_acceptable
    req "/", "text/plain"
    assert_equal 406, last_response.status
  end

  def test_not_found
    req "/_not_there_"
    assert_equal 404, last_response.status
  end
  
  # Skip on Win.. 
  def test_forbidden        
    no_access = "#{@tmpdir}/nope"
    Dir.mkdir(no_access)
    File.chmod(0, no_access) 
    req "/nope"
    assert_equal 403, last_response.status
  end
end
