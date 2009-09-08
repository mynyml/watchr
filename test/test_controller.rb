require 'test/test_helper'

class TestController < Test::Unit::TestCase
  include Watchr

  def to_p(str)
    Pathname(str).expand_path
  end

  def setup
    @loop       = Rev::Loop.default
    @script     = Script.new
    @controller = Controller.new(@script)
    @loop.stubs(:run)
  end

  def teardown
    SingleFileWatcher.controller = nil
    Rev::Loop.default.watchers.every.detach
  end

  test "triggers listening state on run" do
    @loop.expects(:run)
    @controller.run
  end

  ## monitored paths list

  test "fetches monitored paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    script = Script.new
    script.watch('.\.z') { :x }

    contrl = Controller.new(script)
    contrl.monitored_paths.should include(to_p('b/x.z'))
    contrl.monitored_paths.should include(to_p('b/c/y.z'))
  end

  test "doesn't fetch unmonitored paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    script = Script.new
    script.watch('.\.z') { :x }

    contrl = Controller.new(script)
    contrl.monitored_paths.should exclude(to_p('a'))
    contrl.monitored_paths.should exclude(to_p('b/c'))
    contrl.monitored_paths.should exclude(to_p('p/q.z'))
  end

  test "monitored paths include script" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w( a ))
    Script.any_instance.stubs(:parse!)

    path   = to_p('some/file')
    script = Script.new(path)
    contrl = Controller.new(script)
    contrl.monitored_paths.should include(path)
  end

  ## on update

  test "calls action for path" do
    path = to_p('abc')
    @script.expects(:action_for).with(path).returns(lambda {})

    @controller.update('abc')
  end

  test "reloads script" do
    path = to_p('abc')
    @script.stubs(:path).returns(path)
    @script.expects(:parse!)

    @controller.run
    @controller.update('abc')
  end

  ## monitoring file events

  test "listens for events on monitored files" do
    @controller.stubs(:monitored_paths).returns %w{ foo bar }
    @controller.run
    @loop.watchers.size.should be(2)
    @loop.watchers.every.path.should include('foo', 'bar')
    @loop.watchers.every.class.uniq.should be([SingleFileWatcher])
  end

  test "file event updates controller" do
    watcher = SingleFileWatcher.new('foo/bar')
    watcher.stubs(:path).returns('foo/bar')

    @controller.expects(:update).with('foo/bar', :changed)
    watcher.on_change
  end

  ## on the fly updates of monitored files list

  test "refreshes on script file update" do
    path = to_p('abc')
    @script.stubs(:path).returns(path)

    @controller.expects(:refresh)
    @controller.update('abc')
  end

  test "reattaches to new monitored files" do
    @controller.stubs(:monitored_paths).returns %w{ foo bar }
    @controller.run
    @loop.watchers.size.should be(2)
    @loop.watchers.every.path.should include('foo')
    @loop.watchers.every.path.should include('bar')

    @controller.stubs(:monitored_paths).returns %w{ baz bax }
    @controller.refresh
    @loop.watchers.size.should be(2)
    @loop.watchers.every.path.should include('baz')
    @loop.watchers.every.path.should include('bax')
    @loop.watchers.every.path.should exclude('foo')
    @loop.watchers.every.path.should exclude('bar')
  end
end



__END__

require 'test/test_helper'
require 'observer'

class MockEventHandler
  include Observable
  def listen(paths)   end
  def refresh(paths)  end
end

class MockScript
  def parse!()         end
  def action_for(path) end
  def patterns() []    end
  def path()           end
end

class TestController < Test::Unit::TestCase
  include Watchr

  def to_p(str)
    Pathname(str).expand_path
  end

  def setup
    @script     = MockScript.new
    @handler    = MockEventHandler.new
    @controller = Controller.new(@script, @handler)
  end

  test "observer api" do
    assert @controller.respond_to?(:update)
  end

  test "adds itself as an EventHandler observer on run" do
    @handler.instance_variable_get(:@observer_peers).should include(@controller)
  end

  test "triggers handler's monitoring state on run" do
    @handler.expects(:listen).with {|*args| args.first.respond_to?(:each) }
    @controller.run
  end

  test "fetches monitored paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    script = Script.new
    script.watch('.\.z') { :x }

    contrl = Controller.new(script)
    contrl.monitored_paths.should include(to_p('b/x.z'))
    contrl.monitored_paths.should include(to_p('b/c/y.z'))
  end

  test "doesn't fetch unmonitored paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    script = Script.new
    script.watch('.\.z') { :x }

    contrl = Controller.new(script)
    contrl.monitored_paths.should exclude(to_p('a'))
    contrl.monitored_paths.should exclude(to_p('b/c'))
    contrl.monitored_paths.should exclude(to_p('p/q.z'))
  end

  test "monitored paths include script" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w( a ))
    Script.any_instance.stubs(:parse!)

    path   = to_p('some/file')
    script = Script.new(path)
    contrl = Controller.new(script)
    contrl.monitored_paths.should include(path)
  end

  ## on update

  test "calls action for path" do
    path = to_p('abc')
    @script.expects(:action_for).with(path).returns(lambda {})

    @controller.update('abc')
  end

  test "reloads script" do
    path = to_p('abc')
    @script.stubs(:path).returns(path)
    @script.expects(:parse!)

    @controller.run
    @controller.update('abc')
  end

  test "spawns new handler when script changes" do
    path = to_p('abc')
    @controller.run

    @handler.expects(:refresh).at_least_once

    @script.stubs(:path).returns(path)
    @controller.update('abc')
  end
end

