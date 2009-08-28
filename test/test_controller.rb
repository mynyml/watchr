require 'test/test_helper'
require 'observer'

class MockEventHandler
  include Observable
  def listen(o_paths) end
end

class MockScript
  def parse!()         end
  def action_for(path) end
  def patterns() []    end
  def path()           end
end

class TestController < Test::Unit::TestCase
  include Watchr

  def setup
    @handler = MockEventHandler.new
    @controller = Controller.new(MockScript.new, @handler)
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

  test "fetches observed paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    script = Script.new
    script.watch('.\.z') { :x }

    contrl = Controller.new(script)
    contrl.observed_paths.should include('b/x.z')
    contrl.observed_paths.should include('b/c/y.z')
  end

  test "doesn't fetch unobserved paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    script = Script.new
    script.watch('.\.z') { :x }

    contrl = Controller.new(script)
    contrl.observed_paths.should exclude('a')
    contrl.observed_paths.should exclude('b/c')
    contrl.observed_paths.should exclude('p/q.z')
  end

  test "observed paths include script" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w( a ))
    Script.any_instance.stubs(:parse!)

    script = Script.new(Pathname('some/file'))
    contrl = Controller.new(script)
    contrl.observed_paths.should include('some/file')
  end

  ## on update

  test "calls action for path" do
    path = Pathname('abc')
    MockScript.any_instance.stubs(:path).returns(Pathname(''))
    MockScript.any_instance.expects(:action_for).with(path).returns(lambda {})

    @controller.update(path)
  end

  test "reloads script" do
    path = Pathname('abc')
    MockScript.any_instance.stubs(:path).returns(path)
    MockScript.any_instance.expects(:parse!)

    @controller.update(path)
  end
end

