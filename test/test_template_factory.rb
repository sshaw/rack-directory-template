require "json"
require "rack/utils"
require "rexml/document"
require "rack/directory_template/template_factory"

class TestTemplateFactory < DirectoryTemplateTest
  include REXML

  def setup
    @dir = dir_fixture
  end

  def test_html_for_root
    @dir[:url] = "/"
    html = Factory.html(@dir)
    doc  = Document.new(html)
    escaped = Rack::Utils::escape_html(@dir[:url])

    assert_equal escaped, doc.get_text("//title").to_s
    assert_equal escaped, doc.get_text("//h1").to_s

    rows = doc.get_elements("//tr")
    assert_equal 2, rows.size   # heading and dir entry

    file = @dir[:files][0]
    expected = [:name, :size, :type, :mtime].map { |k| file[k] }
    rendered = rows[1].get_elements("td/descendant-or-self::[text()]").map { |e| e.text }
    assert_equal expected, rendered
    
    link = rows[1].get_elements("td/a").first   # check the link to the file
    assert_not_nil link
    assert_equal file[:url], link.attribute("href").to_s   
  end
  
  def test_html_for_subdir
    html = Factory.html(@dir)
    doc  = Document.new(html)
    escaped = Rack::Utils::escape_html(@dir[:url])
    
    assert_equal escaped, doc.get_text("//title").to_s
    assert_equal escaped, doc.get_text("//h1").to_s

    rows = doc.get_elements("//tr")
    assert_equal 3, rows.size   # heading, updir and dir entry

    link = rows[1].get_elements("td/a[text()='Parent Directory']").first
    assert_not_nil link
    assert_equal "/", link.attribute("href").to_s     

    name = rows[2].get_elements("td/a").first
    assert_not_nil name
    assert_equal @dir[:files][0][:name], name.text
  end

  def test_html_filename_escaped
    @dir[:files][0][:name] = "a&b"
    html = Factory.html(@dir)
    doc  = Document.new(html)    
    assert_equal "a&amp;b", doc.get_text("//tr[3]/td/a").to_s
  end

  def test_json
    json = JSON.parse(Factory.json(@dir), :symbolize_names => true)
    assert_equal @dir, json
  end
  
  def test_xml
    xml = Factory.xml(@dir)
    doc = Document.new(xml)    
    assert_equal "directory", doc.root.name

    names = [:url, :name, :size, :type, :mtime]
    names.each do |name|
      nodes = doc.get_elements("/directory/#{name}")
      assert_equal 1, nodes.size, "number of #{name} elements"
      assert_equal @dir[name], nodes[0].text, name
    end

    nodes = doc.get_elements("/directory/files/file")
    assert_equal 1, nodes.size

    names.each do |name| 
      node = nodes[0].get_elements(name.to_s)
      assert_equal 1, node.size, "number of #{name} elements"
      assert_equal @dir[:files][0][name], node[0].text, name
    end
  end

  def test_xml_filename_escaped
    @dir[:files][0][:name] = "a&b"
    xml = Factory.xml(@dir)
    doc  = Document.new(xml)    
    assert_equal "a&amp;b", doc.get_text("//files/file[1]/name").to_s
  end

  # def test_recursive_xml
  # end

  private
  def file_fixture(level = 0)
    entry = {}
    [:url, :name, :size, :type, :mtime].each do |name|
      entry[name] = "#{name}#{level}"
    end
    entry[:url] = "/#{entry[:url]}"
    entry
  end

  def dir_fixture
    dir = file_fixture
    dir[:files] = [ file_fixture(1) ]
    dir
  end
end
