require "directory_template_test"

class TestParamOption < DirectoryTemplateTest
  def setup
    @tmpdir  = Dir.mktmpdir
    tree = mktree(@tmpdir, ["A", "Dir X" => [ "B C" ]])

    # By default if no param is given the root dir is listed. 
    # Is this "expected", or should a 404 be sent?
    @listing = tree[:files].find { |e| e[:name] == "Dir X" }
    RR.reset
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
    RR.verify
  end

  def app
    Rack::DirectoryTemplate.new @tmpdir, :param => "path", :recurse => true
  end

  def test_post
    mock(Factory).html(@listing)
    post "/", :path => "/Dir X"
    assert_equal 200, last_response.status
  end
  
  def test_get
    mock(Factory).html(@listing)
    get "/", :path => "/Dir X"
    assert_equal 200, last_response.status
  end

  def test_www_encoded_file
    get "/", :path => "/Dir X/B C"    
    assert_equal 200, last_response.status
    # The file's contents are its name
    assert_equal "B C", last_response.body
  end

  #def test_url_is_ignored
  #end
end
