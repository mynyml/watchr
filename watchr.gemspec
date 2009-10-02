
Gem::Specification.new do |s|
  s.name              = 'watchr'
  s.version           = '0.5.7'
  s.summary           = "Modern continious testing (flexible alternative to autotest)"
  s.description       = "Modern continious testing (flexible alternative to autotest)."
  s.author            = "mynyml"
  s.email             = 'mynyml@gmail.com'
  s.homepage          = 'http://mynyml.com/ruby/flexible-continuous-testing'
  s.has_rdoc          = true
  s.rdoc_options      = %w( --main README.rdoc )
  s.extra_rdoc_files  = %w( README.rdoc )
  s.require_path      = "lib"
  s.bindir            = "bin"
  s.executables       = "watchr"
  s.files = %w[
    .gitignore
    History.txt
    LICENSE
    Manifest
    README.rdoc
    Rakefile
    TODO.txt
    bin/watchr
    docs.watchr
    gem.watchr
    lib/watchr.rb
    lib/watchr/controller.rb
    lib/watchr/event_handlers/base.rb
    lib/watchr/event_handlers/portable.rb
    lib/watchr/event_handlers/unix.rb
    lib/watchr/script.rb
    manifest.watchr
    specs.watchr
    test/README
    test/event_handlers/test_base.rb
    test/event_handlers/test_portable.rb
    test/event_handlers/test_unix.rb
    test/test_controller.rb
    test/test_helper.rb
    test/test_script.rb
    test/test_watchr.rb
    watchr.gemspec
  ]
  s.test_files = %w[
    test/test_helper.rb
    test/test_watchr.rb
    test/test_script.rb
    test/test_controller.rb
    test/event_handlers/test_base.rb
    test/event_handlers/test_unix.rb
    test/event_handlers/test_portable.rb
  ]

  s.add_development_dependency 'mocha'
  s.add_development_dependency 'jeremymcanally-matchy'
  s.add_development_dependency 'jeremymcanally-pending'
  s.add_development_dependency 'mynyml-every'
  s.add_development_dependency 'mynyml-redgreen'
end
