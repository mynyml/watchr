require 'pathname'
require 'tmpdir'
require 'tempfile'
require 'fileutils'

require 'minitest/autorun'
require 'mocha'
require 'every'
begin
  require 'redgreen' #http://gemcutter.org/gems/mynyml-redgreen
  require 'phocus'
  require 'ruby-debug'
rescue LoadError, RuntimeError
end

require 'watchr'

class MiniTest::Unit::TestCase
  class << self
    def test(name, &block)
      define_method("test_#{name.gsub(/\s/,'_')}", &block)
    end
    alias :should :test

    # noop
    def xtest(*args) end
  end
end

unless Watchr::HAVE_COOLIO
  puts "Skipping Unix handler tests. Install Coolio (gem install coolio) to properly test full suite"
end

unless Watchr::HAVE_FSE
  puts "Skipping Darwin handler tests. Install FSEvent (gem install ruby-fsevent) to properly test full suite (osx only)"
end

