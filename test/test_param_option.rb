require "test_helper"

class TestParamOption < Test::Unit::TestCase
  def setup
    @tmpdir  = Dir.mktmpdir
    @tree = mktree(@tmpdir, ["A", {"Dir X" => [ "B C" ]}])
    # By default if no param is given the root dir is listed. 
    # Is this "expected", or should a 404 be sent?
    @listing = @tree[:files].find { |e| e[:name] == "Dir X" }
    RR.reset
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  def app
    Rack::DirectoryTemplate.new @tmpdir, :param => "path", :recurse => true
  end

  def test_post
    stub(Factory).html
    post "/", {:path => "/Dir X"}, "HTTP_ACCEPT" => "text/html"
    assert_equal 200, last_response.status
    assert_received(Factory) { |s| s.html(@listing) }
  end
  
  def test_get
    stub(Factory).html
    req "/", :path => "/Dir X"
    assert_equal 200, last_response.status
    assert_received(Factory) { |s| s.html(@listing) }
  end

  def test_request_for_file
    req "/", :path => "/Dir X/B C"    
    assert_equal 200, last_response.status
    # The file's contents are its name
    assert_equal "B C", last_response.body
  end

  def test_url_is_ignored
    stub(Factory).html
    req "/Dir%20X/B%20C", :path => "/"    
    assert_equal 200, last_response.status
    assert_received(Factory) { |s| s.html(@tree) }
  end
end
