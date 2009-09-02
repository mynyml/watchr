require 'test/test_helper'
require 'tmpdir'

# names must represent paths to files, not directories
# directories will be created automatically
def with_fixtures(names=[], &block)
  Dir.mktmpdir('watchr-') do |dir|
    dir = Pathname(dir)
    names.each do |name|
      (dir + name).dirname.mkpath
      (dir + name).open('w') {|f| f << "fixture\n" }
    end
    block.call(dir)
  end
end

class MockObserver
  attr_accessor :notified

  def update(*args)
    @notified = args
  end
  def notified?
    !!@notified
  end
  def notified_with?(*expected)
    expected == @notified[0..(expected.size - 1)].compact if notified?
  end
  def reset
    @notified = nil
  end
end

Thread.abort_on_exception = true

# TODO extract common code
class TestEventHandler < Test::Unit::TestCase

  test "api" do
    handler = Watchr.handler.new
    handler.should respond_to(:delay)
    handler.should respond_to(:listen)
    handler.should respond_to(:add_observer)
    handler.should respond_to(:monitored_paths)
  end

  # TODO split into one spec for each event type
  test "notifies observers on events to monitored files" do
    with_fixtures %w( aaa bbb ) do |dir|

      begin
        handler = Watchr.handler.new
        p = {
          :aaa => dir + 'aaa',
          :bbb => dir + 'bbb'
        }

        observer = MockObserver.new
        handler.add_observer(observer)

        listening = Thread.new {
          handler.monitored_paths = p.values
          handler.listen
        }
        listening.priority = 10

        Timeout.timeout(1.5) do
          observer.reset
          FileUtils.touch(p[:aaa]) # change of file attributes
          listening.run until observer.notified?
          assert observer.notified_with?(p[:aaa].to_s), "expected observer to be notified with #{p[:aaa]}, got #{observer.notified.inspect}"
        end

        Timeout.timeout(1.5) do
          observer.reset
          p[:bbb].open('w') {|f| f << 'ohaie' } # file modified
          listening.run until observer.notified?
          assert observer.notified_with?(p[:bbb].to_s), "expected observer to be notified with #{p[:bbb]}, got #{observer.notified.inspect}"
        end
      rescue Timeout::Error
        flunk("Event notification timed out. The handler either didn't pick up the file update, or it took too long to report it.")
      ensure
        listening.terminate
      end
    end
  end

  test "ignores events on unmonitored files" do
    with_fixtures %w( aaa bbb ) do |dir|
      handler = Watchr.handler.new
      p = {
        :aaa => dir + 'aaa',
        :bbb => dir + 'bbb'
      }

      observer = MockObserver.new
      handler.add_observer(observer)

      listening = Thread.new {
        handler.monitored_paths = p.values
        handler.listen
      }
      listening.priority = 10

      FileUtils.touch(dir + 'ccc')
      100.times { listening.run }
      sleep( handler.delay || 0.1 )
      assert !observer.notified?

      listening.terminate
    end
  end

  test "updates list of monitored files" do
  end
end
