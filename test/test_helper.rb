require 'pathname'
#require 'tmpdir'
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

root = Pathname(__FILE__).dirname.parent.expand_path
$:.unshift(root.join('lib').to_s).uniq!

require 'watchr'

class Test::Unit::TestCase
  class << self
    def test(name, &block)
      name = :"test_#{name.gsub(/\s/,'_')}"
      define_method(name, &block)
    end
    alias :should :test

    # noop
    def xtest(*args) end
  end
end

# taken from minitest/unit.rb
# (with modifications)
def capture_io
  require 'stringio'

  orig_stdout, orig_stderr         = $stdout, $stderr
  captured_stdout, captured_stderr = StringIO.new, StringIO.new
  $stdout, $stderr                 = captured_stdout, captured_stderr

  yield

  return Struct.new(:stdout, :stderr).new(
    captured_stdout.string,
    captured_stderr.string
  )
ensure
  $stdout = orig_stdout
  $stderr = orig_stderr
end

## names must represent paths to files, not directories
## directories will be created automatically
#def with_fixtures(names=[], &block)
#  Dir.mktmpdir('watchr-') do |dir|
#    dir = Pathname(dir)
#    names.each do |name|
#      (dir + name).dirname.mkpath
#      (dir + name).open('w') {|f| f << "fixture\n" }
#    end
#    block.call(dir)
#  end
#end
