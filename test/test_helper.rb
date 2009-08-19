require 'pathname'
require 'test/unit'
require 'matchy'
require 'mocha'
require 'every'
require 'pending'
begin
  require 'ruby-debug'
  require 'phocus'
  require 'redgreen'
rescue LoadError, RuntimeError
end

ROOT = Pathname(__FILE__).dirname.parent
$:.unshift(ROOT.join('lib'))

require 'watchr'

class Test::Unit::TestCase
  class << self
    def test(name, &block)
      name = :"test_#{name.gsub(/\s/,'_')}"
      define_method(name, &block)
    end
    alias :should :test
  end
end

class Pathname
  def rel
    self.relative_path_from(ROOT).to_s
  end
  def pattern
    Regexp.escape(self.rel)
  end
  def touch
    `touch #{self.expand_path.to_s}`
    self
  end
end

class Fixture
  FIXDIR = Pathname(__FILE__).dirname.join('fixtures')

  class << self
    attr_accessor :files

    def create(name=nil)
      name ||= 'a.rb'
      file = FIXDIR.join(name)
      self.files ||= []
      self.files << file
      file.open('w+') {|f| f << "fixture\n" }
      file
    end
  end
end
