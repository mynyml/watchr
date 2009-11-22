require 'pathname'
require 'tempfile'
require 'set'

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

unless Watchr::HAVE_REV
  puts "Skipping Unix handler tests. Install Rev (gem install rev) to properly test full suite"
end

