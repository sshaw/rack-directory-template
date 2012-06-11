require "directory_template_test"

class TestRecursion < DirectoryTemplateTest
  def setup
    @tmpdir = Dir.mktmpdir
    @tree = mktree(@tmpdir, ["A" => [ "B" => ["file"]]])
    RR.reset
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
    RR.verify
  end

  def test_listing_is_not_recursive_by_default
    # Remove directory A's children
    @tree[:files][0].delete(:files)
    mock(Factory).html(@tree)

    app = Rack::DirectoryTemplate.new @tmpdir
    t = Rack::Test::Session.new(app)
    t.get("/")    
    assert_equal 200, t.last_response.status
  end

  def test_maximum_depth_not_exceeded
    # Remove directory B's children 
    dirA = @tree[:files][0]
    dirA[:files][0].delete(:files)
    mock(Factory).html(@tree)

    app = Rack::DirectoryTemplate.new @tmpdir, :recurse => 1
    t = Rack::Test::Session.new(app)
    t.get("/")
    assert_equal 200, t.last_response.status
  end
  
  def test_listing_is_recursive
    mock(Factory).html(@tree)

    app = Rack::DirectoryTemplate.new @tmpdir, :recurse => true
    t = Rack::Test::Session.new(app)
    t.get("/")
    assert_equal 200, t.last_response.status
  end
end
