require 'test/test_helper'
require 'tmpdir'

ENV['HANDLER'] ||= 'linux'

HANDLER = case ENV['HANDLER']
when 'linux'
  require Watchr::ROOT + 'lib/watchr/event_handlers/linux_event_handler'
  Watchr::LinuxEventHandler
else
  require Watchr::ROOT + 'lib/watchr/event_handlers/portable_event_handler'
  PortableEventHandler
end

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
    expected == @notified[0..(expected.size)].compact if notified?
  end
  def reset
    @notified = nil
  end
end

Thread.abort_on_exception = true

class TestEventHandler < Test::Unit::TestCase

  test "observable api" do
    handler = HANDLER.new
    assert handler.respond_to?(:delay)
    assert handler.respond_to?(:listen)
    assert handler.respond_to?(:add_observer)
  end

  test "notifies observers on events to monitored files" do
    with_fixtures %w( aaa bbb ) do |dir|

      begin
        handler = HANDLER.new
        p = {
          :aaa => dir + 'aaa',
          :bbb => dir + 'bbb'
        }

        observer = MockObserver.new
        handler.add_observer(observer)

        listening = Thread.new { handler.listen(p.values) }
        listening.priority = 10

        Timeout.timeout(1.5) do
          observer.reset
          FileUtils.touch(p[:aaa])
          listening.run until observer.notified?
          assert observer.notified_with?(p[:aaa]), "expected observer to be notified with #{p[:aaa]}, got #{observer.notified}"
        end
        Timeout.timeout(1.5) do
          observer.reset
          FileUtils.touch(p[:bbb])
          listening.run until observer.notified?
          assert observer.notified_with?(p[:bbb]), "expected observer to be notified with #{p[:bbb]}, got #{observer.notified}"
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
      handler = HANDLER.new
      p = {
        :aaa => dir + 'aaa',
        :bbb => dir + 'bbb'
      }

      observer = MockObserver.new
      handler.add_observer(observer)

      listening = Thread.new { handler.listen(p.values) }
      listening.priority = 10

      FileUtils.touch(dir + 'ccc')
      100.times { listening.run }
      sleep( handler.delay || 0.1 )
      assert !observer.notified?

      listening.terminate
    end
  end
end
