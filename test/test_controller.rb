require 'test/test_helper'
require 'observer'

class MockHandler
  include Observable
  def listen(paths)  end
  def refresh(paths) end
end

class TestController < Test::Unit::TestCase
  include Watchr

  def to_p(str)
    Pathname(str).expand_path
  end

  def setup
    tmpfile     = Tempfile.new('foo')
    @script     = Script.new( Pathname.new( tmpfile.path ) )
    @handler    = MockHandler.new
    @controller = Controller.new(@script, @handler)
  end

  test "triggers listening state on run" do
    @controller.stubs(:monitored_paths).returns %w( foo bar )
    @handler.expects(:listen).with %w( foo bar )
    @controller.run
  end

  test "adds itself as handler observer" do
    @handler.count_observers.should be(1)
    @handler.delete_observer(@controller)
    @handler.count_observers.should be(0)
  end

  ## monitored paths list

  test "fetches monitored paths" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w(
      a
      b/x.z
      b/c
      b/c/y.z
    ))
    @script.watch('.\.z') { :x }

    contrl = Controller.new(@script, MockHandler.new)
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
    @script.watch('.\.z') { :x }

    contrl = Controller.new(@script, MockHandler.new)
    contrl.monitored_paths.should exclude(to_p('a'))
    contrl.monitored_paths.should exclude(to_p('b/c'))
    contrl.monitored_paths.should exclude(to_p('p/q.z'))
  end

  test "monitored paths include script" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w( a ))
    Script.any_instance.stubs(:parse!)

    path   = to_p('some/file')
    script = Script.new(path)
    contrl = Controller.new(script, MockHandler.new)
    contrl.monitored_paths.should include(path)
  end

  ## on update

  test "calls action for path" do
    path = to_p('abc')
    @script.expects(:action_for).with(path, :modified).returns(lambda {})

    @controller.update('abc', :modified)
  end

  test "parses script on script file update" do
    path = to_p('abc')
    @script.stubs(:path).returns(path)
    @script.expects(:parse!)

    @controller.update('abc')
  end

  test "refreshes handler on script file update" do
    path = to_p('abc')
    @script.stubs(:path).returns(path)
    @controller.stubs(:monitored_paths).returns %w( foo bar )

    @handler.expects(:refresh).with %w( foo bar )
    @controller.update(path)
  end
end

