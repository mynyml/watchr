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

root = Pathname(__FILE__).dirname.parent
require root + 'lib/watchr'

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
    self.relative_path_from(Watchr::LIBROOT).to_s
  end
  def pattern
    Regexp.escape(self.rel)
  end
  def touch(time = Time.now)
    `touch -mt #{time.strftime('%Y%m%d%H%M.%S')} #{self.expand_path.to_s}`
    self
  end
  def mtime=(t)
    self.touch(t).mtime
  end
end

class Fixture
  DIR = Pathname(__FILE__).dirname.join('fixtures')

  class << self
    attr_accessor :files

    def create(name=nil, content=nil)
      name ||= 'a.rb'
      file = DIR.join(name)
      self.files ||= []
      self.files << file
      file.open('w+') {|f| f << (content || "fixture\n") }
      file
    end

    def delete_all
      DIR.entries.each do |fixture|
        next if %w( .. . ).include?(fixture.to_s)
        DIR.join(fixture.to_s).expand_path.delete
      end
    end
  end
end
