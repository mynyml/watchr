require 'test/test_helper'
require 'observer'

class MockEventHandler
  include Observable
  attr_accessor :monitored_paths
  def listen() end
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
    @handler = MockEventHandler.new
    @controller = Controller.new(MockScript.new, @handler)
  end

  test "observer api" do
    assert @controller.respond_to?(:update)
  end

  test "adds itself as an EventHandler observer" do
    @handler.count_observers.should be(1)
    @handler.delete_observer(@controller)
    @handler.count_observers.should be(0)
  end

  test "run triggers handler's monitoring state" do
    @handler.expects(:listen)
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
    MockScript.any_instance.expects(:action_for).with(path).returns(lambda {})

    @controller.update('abc')
  end

  test "reloads script" do
    path = to_p('abc')
    MockScript.any_instance.stubs(:path).returns(path)
    MockScript.any_instance.expects(:parse!)

    @controller.update('abc')
  end
end

