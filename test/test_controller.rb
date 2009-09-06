require 'test/test_helper'
require 'observer'

class MockEventHandler
  include Observable
  def listen(paths) end
  def refresh()     end
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

