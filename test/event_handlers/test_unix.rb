require 'test/test_helper'

if Watchr::HAVE_REV

class Watchr::EventHandler::Unix::SingleFileWatcher
  public :type
end

class UnixEventHandlerTest < Test::Unit::TestCase
  include Watchr

  SingleFileWatcher = EventHandler::Unix::SingleFileWatcher

  def setup
    @now = Time.now
    pathname = Pathname.new('foo/bar')
    pathname.stubs(:atime ).returns(@now)
    pathname.stubs(:mtime ).returns(@now)
    pathname.stubs(:ctime ).returns(@now)
    pathname.stubs(:exist?).returns(true)
    SingleFileWatcher.any_instance.stubs(:pathname).returns(pathname)

    @loop    = Rev::Loop.default
    @handler = EventHandler::Unix.new
    @watcher = SingleFileWatcher.new('foo/bar')
    @loop.stubs(:run)
  end

  def teardown
    SingleFileWatcher.handler = nil
    Rev::Loop.default.watchers.every.detach
  end

  test "triggers listening state" do
    @loop.expects(:run)
    @handler.listen([])
  end

  ## SingleFileWatcher

  test "watcher pathname" do
    @watcher.pathname.should be_kind_of(Pathname)
    @watcher.pathname.to_s.should be(@watcher.path)
  end

  test "stores reference times" do
    @watcher.pathname.stubs(:atime).returns(:time)
    @watcher.pathname.stubs(:mtime).returns(:time)
    @watcher.pathname.stubs(:ctime).returns(:time)

    @watcher.send(:update_reference_times)
    @watcher.instance_variable_get(:@reference_atime).should be(:time)
    @watcher.instance_variable_get(:@reference_mtime).should be(:time)
    @watcher.instance_variable_get(:@reference_ctime).should be(:time)
  end

  test "stores initial reference times" do
    SingleFileWatcher.any_instance.expects(:update_reference_times)
    SingleFileWatcher.new('foo')
  end

  test "updates reference times on change" do
    @watcher.expects(:update_reference_times)
    @watcher.on_change
  end

  test "detects event type" do
    trigger_event @watcher, @now, :atime
    @watcher.type.should be(:accessed)

    trigger_event @watcher, @now, :mtime
    @watcher.type.should be(:modified)

    trigger_event @watcher, @now, :ctime
    @watcher.type.should be(:changed)

    trigger_event @watcher, @now, :atime, :mtime
    @watcher.type.should be(:modified)

    trigger_event @watcher, @now, :mtime, :ctime
    @watcher.type.should be(:modified)

    trigger_event @watcher, @now, :atime, :ctime
    @watcher.type.should be(:accessed)

    trigger_event @watcher, @now, :atime, :mtime, :ctime
    @watcher.type.should be(:modified)

    @watcher.pathname.stubs(:exist?).returns(false)
    @watcher.type.should be(:deleted)
  end

  ## monitoring file events

  test "listens for events on monitored files" do
    @handler.listen %w( foo bar )
    @loop.watchers.size.should be(2)
    @loop.watchers.every.path.should include('foo', 'bar')
    @loop.watchers.every.class.uniq.should be([SingleFileWatcher])
  end

  test "notifies observers on file event" do
    @watcher.stubs(:path).returns('foo')
    @handler.expects(:notify).with('foo', anything)
    @watcher.on_change
  end

  test "notifies observers of event type" do
    trigger_event @watcher, @now, :atime
    @handler.expects(:notify).with('foo/bar', :accessed)
    @watcher.on_change

    trigger_event @watcher, @now, :mtime
    @handler.expects(:notify).with('foo/bar', :modified)
    @watcher.on_change

    trigger_event @watcher, @now, :ctime
    @handler.expects(:notify).with('foo/bar', :changed)
    @watcher.on_change

    trigger_event @watcher, @now, :atime, :mtime, :ctime
    @handler.expects(:notify).with('foo/bar', :modified)
    @watcher.on_change

    @watcher.pathname.stubs(:exist?).returns(false)
    @handler.expects(:notify).with('foo/bar', :deleted)
    @watcher.on_change
  end

  ## on the fly updates of monitored files list

  test "reattaches to new monitored files" do
    @handler.listen %w( foo bar )
    @loop.watchers.size.should be(2)
    @loop.watchers.every.path.should include('foo')
    @loop.watchers.every.path.should include('bar')

    @handler.refresh %w( baz bax )
    @loop.watchers.size.should be(2)
    @loop.watchers.every.path.should include('baz')
    @loop.watchers.every.path.should include('bax')
    @loop.watchers.every.path.should exclude('foo')
    @loop.watchers.every.path.should exclude('bar')
  end

  private

  def trigger_event(watcher, now, *types)
    watcher.pathname.stubs(:atime).returns(now)
    watcher.pathname.stubs(:mtime).returns(now)
    watcher.pathname.stubs(:ctime).returns(now)
    watcher.instance_variable_set(:@reference_atime, now)
    watcher.instance_variable_set(:@reference_mtime, now)
    watcher.instance_variable_set(:@reference_ctime, now)

    types.each do |type|
      watcher.pathname.stubs(type).returns(now+10)
    end
  end
end

end  # if Watchr::HAVE_REV
