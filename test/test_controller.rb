require 'test/test_helper'
require 'observer'

class MockHandler
  include Observable
  def listen(paths)  end
  def refresh(paths) end
end

class TestController < MiniTest::Unit::TestCase
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

  test "parses the script on #run" do
    @script.expects(:parse!)
    @controller.run
  end

  test "adds itself as handler observer" do
    assert_equal 1, @handler.count_observers
    @handler.delete_observer(@controller)
    assert_equal 0, @handler.count_observers
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
    assert_includes contrl.monitored_paths, to_p('b/x.z')
    assert_includes contrl.monitored_paths, to_p('b/c/y.z')
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
    refute_includes contrl.monitored_paths, to_p('a')
    refute_includes contrl.monitored_paths, to_p('b/c')
    refute_includes contrl.monitored_paths, to_p('p/q.z')
  end

  test "monitored paths include script" do
    Dir.expects(:[]).at_least_once.with('**/*').returns(%w( a ))
    Script.any_instance.stubs(:parse!)

    path   = to_p('some/file')
    script = Script.new(path)
    contrl = Controller.new(script, MockHandler.new)
    assert_includes contrl.monitored_paths, path
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

  test "exits gracefully when Interrupted" do
    @handler.stubs(:listen).raises(Interrupt)
    @controller.run
  end

  test "does not parse script on mere script file access" do
    path = to_p('abc')
    @script.stubs(:path).returns(path)
    @script.expects(:parse!).never

    @controller.update('abc', :accessed)
  end
end

