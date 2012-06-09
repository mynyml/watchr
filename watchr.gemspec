require './lib/watchr'

Gem::Specification.new do |s|
  s.name                = "watchr"
  s.summary             = "Modern continious testing (flexible alternative to autotest)"
  s.description         = "Modern continious testing (flexible alternative to autotest)."
  s.author              = "mynyml"
  s.email               = "mynyml@gmail.com"
  s.homepage            = "http://mynyml.com/ruby/flexible-continuous-testing"
  s.rubyforge_project   = "watchr"
  s.require_path        = "lib"
  s.bindir              = "bin"
  s.executables         = "watchr"
  s.version             =  Watchr::VERSION
  s.files               =  `git ls-files`.strip.split("\n")

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'every'
end
