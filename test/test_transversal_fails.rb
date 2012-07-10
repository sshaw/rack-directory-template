require "test_helper"

class TestTransversalFails < Test::Unit::TestCase
  PATHS = ["/../", "/%2e%2e/", "%2e%2e%2f", "/..%2f../"]

  def setup
    @tmpdir = Dir.mktmpdir
    @listing = mktree(@tmpdir, ['A'])
    RR.reset
  end

  def teardown 
    FileUtils.rm_rf(@tmpdir)
  end

  def test_transverse_path
    t = session(@tmpdir)
    # The path gets used at the top level :url arg to html()!
    PATHS.each do |path| 
      stub(Factory).html
      t.get(path) 

      assert_received(Factory) { |s| s.html(@listing) }
    end
  end

  def test_transverse_with_param
    t = session(@tmpdir, :param => "file")   
    PATHS.each do |path| 
      stub(Factory).html
      t.get("/", :file => path) 

      assert_received(Factory) { |s| s.html(@listing) }
    end
  end
end
