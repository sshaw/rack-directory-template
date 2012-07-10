require "test_helper"

class TestRecursion < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @tree = mktree(@tmpdir, ["A" => [ "B" => ["file"]]])
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  def test_listing_is_not_recursive_by_default
    # Remove directory A's children
    @tree[:files][0].delete(:files)

    stub(Factory).html
    t = session(@tmpdir)
    t.get("/")

    assert_equal 200, t.last_response.status
    assert_received(Factory) { |s| s.html(@tree) }
  end

  def test_maximum_depth_not_exceeded
    # Remove directory B's children 
    dirA = @tree[:files][0]
    dirA[:files][0].delete(:files)

    stub(Factory).html
    t = session(@tmpdir, :recurse => 1)
    t.get("/")

    assert_equal 200, t.last_response.status
    assert_received(Factory) { |s| s.html(@tree) }
  end
  
  def test_listing_is_recursive
    stub(Factory).html
    t = session(@tmpdir, :recurse => true)
    t.get("/")

    assert_equal 200, t.last_response.status
    assert_received(Factory) { |s| s.html(@tree) }
  end
end
