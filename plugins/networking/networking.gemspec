$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "networking/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "networking"
  s.version     = Networking::VERSION
  s.authors     = ["Andreas Pfau"]
  s.email       = ["andreas.pfau@sap.com"]
  s.homepage    = ""
  s.summary     = "Summary of Network."
  s.description = "Description of Network."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

end