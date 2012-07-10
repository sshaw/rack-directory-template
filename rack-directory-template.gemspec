Gem::Specification.new do |s|
  s.name        = "rack-directory-template"
  s.version     = "0.0.1"
  s.date        = Date.today
  s.summary     = "Generate directory listings in HTML, JSON, or XML. Customize your responses via ERB templates and/or callbacks."
  s.description =<<-DESC
    Rack::DirectoryTemplate is a Rack endpoint for directory listings that examines the request's Accept header and generates a reply in the prefered format.
    Currently supports HTML, JSON, and XML. Suitable defaults are provided for each format. 
    Customization is possible via ERB templates and/or callbacks.

    Directory names can also be given via a request parameter.
  DESC
  s.authors     = ["Skye Shaw"]
  s.email       = "sshaw@lucas.cis.temple.edu"
  s.files       = Dir["lib/**/*.rb", "README.rdoc"]
  s.test_files  = Dir["test/*.rb"]
  s.homepage    = "http://github.com/sshaw/rack-directory-template"
  s.license     = "MIT"
  s.required_ruby_version = ">= 1.8.7"
  s.add_dependency "json"
  s.add_dependency "rack-accept", "~> 0.4.4"
  s.add_development_dependency "rack-test", "~> 0.6.1"
  s.extra_rdoc_files = ["README.rdoc"]
end
