require "json"
require "rack/utils"

module Rack
  class DirectoryTemplate
    class TemplateFactory
      HTML =<<-END
	<html>
	<head>
	  <title>%s</title>
	  <style>
	    table { width: 100%%; }
	    th { text-align: left }
	  </style>
	</head>
	<body>
	<h1>%s</h1>
	<table><tr><th>Name</th><th>Size</th><th>Type</th><th>Mtime</th></tr>
          %s
        </table>
	</body>
	</html>   
      END

      HTML_ROW = "<tr><td><a href='%s'>%s</a></td><td>%s</td><td>%s</td><td>%s</td></tr>"
      HTML_UPDIR = "<tr><td colspan='4'><a href='%s'>Parent Directory</a></td></tr>"
      
      XML = "<?xml version='1.0'?><directory>%s</directory>"
      XML_FILE = "<url>%s</url><name>%s</name><size>%s</size><type>%s</type><mtime>%s</mtime>"
      XML_ENTRY = "<file>#{XML_FILE}</file>"      

      class << self
        def html(listing)
          html = ""
          if listing[:url] != "/" && i = listing[:url].rindex("/")
            html << sprintf(HTML_UPDIR, listing[:url][0, i == 0 ? 1 : i])
          end
          
          listing[:files].each do |file|
            html << entry(HTML_ROW, file)
          end
          
          sprintf HTML, listing[:url], listing[:url], html
        end

        def xml(listing)
          xml = entry(XML_FILE, listing)
          if listing[:files]
            files = listing[:files].inject("") { |files, file| files << entry(XML_ENTRY, file) }
            xml << "<files>#{files}</files>"
          end
          sprintf XML, xml
        end
        
        def json(listing)
          JSON.dump(listing)
        end
        
        private
        def entry(format, entry)
          # :url is already escaped
          sprintf format, entry[:url], Rack::Utils.escape_html(entry[:name]), entry[:size], entry[:type], entry[:mtime] 
        end
      end
    end
  end
end
