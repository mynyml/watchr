require 'test/test_helper'

if Watchr::HAVE_COOLIO

class Watchr::EventHandler::Unix::SingleFileWatcher
  public :type
end

class UnixEventHandlerTest < MiniTest::Unit::TestCase
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

    @loop    = Coolio::Loop.default
    @handler = EventHandler::Unix.new
    @watcher = SingleFileWatcher.new('foo/bar')
    @loop.stubs(:run)
  end

  def teardown
    SingleFileWatcher.handler = nil
    Coolio::Loop.default.watchers.every.detach
  end

  test "triggers listening state" do
    @loop.expects(:run)
    @handler.listen([])
  end

  ## SingleFileWatcher

  test "watcher pathname" do
    assert_instance_of Pathname, @watcher.pathname
    assert_equal @watcher.path, @watcher.pathname.to_s
  end

  test "stores reference times" do
    @watcher.pathname.stubs(:atime).returns(:time)
    @watcher.pathname.stubs(:mtime).returns(:time)
    @watcher.pathname.stubs(:ctime).returns(:time)

    @watcher.send(:update_reference_times)
    assert_equal :time, @watcher.instance_variable_get(:@reference_atime)
    assert_equal :time, @watcher.instance_variable_get(:@reference_mtime)
    assert_equal :time, @watcher.instance_variable_get(:@reference_ctime)
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
    assert_equal :accessed, @watcher.type

    trigger_event @watcher, @now, :mtime
    assert_equal :modified, @watcher.type

    trigger_event @watcher, @now, :ctime
    assert_equal :changed, @watcher.type

    trigger_event @watcher, @now, :atime, :mtime
    assert_equal :modified, @watcher.type

    trigger_event @watcher, @now, :mtime, :ctime
    assert_equal :modified, @watcher.type

    trigger_event @watcher, @now, :atime, :ctime
    assert_equal :accessed, @watcher.type

    trigger_event @watcher, @now, :atime, :mtime, :ctime
    assert_equal :modified, @watcher.type

    @watcher.pathname.stubs(:exist?).returns(false)
    assert_equal :deleted, @watcher.type
  end

  ## monitoring file events

  test "listens for events on monitored files" do
    @handler.listen %w( foo bar )
    assert_equal 2, @loop.watchers.size
    assert_equal %w( foo bar ).to_set, @loop.watchers.every.path.to_set
    assert_equal [SingleFileWatcher], @loop.watchers.every.class.uniq
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
    assert_equal 2, @loop.watchers.size
    assert_includes @loop.watchers.every.path, 'foo'
    assert_includes @loop.watchers.every.path, 'bar'

    @handler.refresh %w( baz bax )
    assert_equal 2, @loop.watchers.size
    assert_includes @loop.watchers.every.path, 'baz'
    assert_includes @loop.watchers.every.path, 'bax'
    refute_includes @loop.watchers.every.path, 'foo'
    refute_includes @loop.watchers.every.path, 'bar'
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

end  # if Watchr::HAVE_COOLIO
