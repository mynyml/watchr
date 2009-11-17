require 'lib/watchr'

Gem::Specification.new do |s|
  s.name                = "watchr"
  s.summary             = "Modern continious testing (flexible alternative to autotest)"
  s.description         = "Modern continious testing (flexible alternative to autotest)."
  s.author              = "mynyml"
  s.email               = "mynyml@gmail.com"
  s.homepage            = "http://mynyml.com/ruby/flexible-continuous-testing"
  s.rubyforge_project   = "watchr"
  s.has_rdoc            =  true
  s.rdoc_options        =  %w( --main README.rdoc )
  s.extra_rdoc_files    =  %w( README.rdoc )
  s.require_path        = "lib"
  s.bindir              = "bin"
  s.executables         = "watchr"
  s.version             =  Watchr::VERSION
  s.files               =  File.read("Manifest").strip.split("\n")

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'every' #http://gemcutter.org/gems/every
end
