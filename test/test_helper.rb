require 'pathname'
require 'test/unit'
require 'matchy'
require 'mocha'
require 'every'
require 'pending'
begin
  require 'ruby-debug'
  require 'redgreen'
  require 'phocus'
rescue LoadError, RuntimeError
end

require Pathname(__FILE__).dirname.parent.join('lib/watchr')

class Test::Unit::TestCase
  class << self
    def test(name, &block)
      name = :"test_#{name.gsub(/\s/,'_')}"
      define_method(name, &block)
    end
    alias :should :test
  end
end

# taken from minitest/unit.rb
def capture_io
  require 'stringio'

  orig_stdout, orig_stderr         = $stdout, $stderr
  captured_stdout, captured_stderr = StringIO.new, StringIO.new
  $stdout, $stderr                 = captured_stdout, captured_stderr

  yield

  return captured_stdout.string, captured_stderr.string
ensure
  $stdout = orig_stdout
  $stderr = orig_stderr
end

__END__
class Pathname
  def rel
    self.relative_path_from(Watchr::ROOT).to_s
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
