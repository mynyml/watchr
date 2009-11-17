require 'test/test_helper'

class TestScript < MiniTest::Unit::TestCase
  include Watchr

  def setup
    @script = Script.new
  end

  ## external api

  test "watch" do
    @script.ec.watch('pattern')
    @script.ec.watch('pattern', :event_type)
    @script.ec.watch('pattern') { nil }
  end

  test "default action" do
    @script.ec.default_action { nil }
  end

  test "reload" do
    @script.ec.reload
  end

  test "eval context delegates methods to script" do
    @script.ec.watch('pattern')
    @script.ec.watch('pattern', :event_type)
    @script.ec.watch('pattern') { nil }
    @script.ec.default_action { :foo }

    assert_equal 3, @script.rules.size
    assert_equal :foo, @script.default_action.call
  end

  ## functionality

  test "rule object" do
    rule = @script.watch('pattern', :modified) { nil }

    assert_equal 'pattern', rule.pattern
    assert_equal :modified, rule.event_type
    assert_equal nil, rule.action.call
  end

  test "default event type" do
    rule = @script.watch('pattern') { nil }
    assert_equal :modified, rule.event_type
  end

  test "finds action for path" do
    @script.watch('abc') { :x }
    @script.watch('def') { :y }
    assert_equal :x, @script.action_for('abc').call
  end

  test "finds action for path with event type" do
    @script.watch('abc', :accessed) { :x }
    @script.watch('abc', :modified) { :y }
    assert_equal :x, @script.action_for('abc', :accessed).call
  end

  test "finds action for path with any event type" do
    @script.watch('abc', nil) { :x }
    @script.watch('abc', :modified) { :y }
    assert_equal :x, @script.action_for('abc', :accessed).call
  end

  test "no action for path" do
    @script.watch('abc', :accessed) { :x }
    assert_nil @script.action_for('abc', :modified).call
  end

  test "collects patterns" do
    @script.watch('abc')
    @script.watch('def')
    assert_includes @script.patterns, 'abc'
    assert_includes @script.patterns, 'def'
  end

  test "parses script file" do
    path = Pathname( Tempfile.open('bar').path )
    path.open('w') {|f| f.write <<-STR }
      watch( 'abc' ) { :x }
    STR
    script = Script.new(path)
    script.parse!
    assert_equal :x, script.action_for('abc').call
  end

  test "__FILE__ is set properly in script file" do
    path = Pathname( Tempfile.open('bar').path )
    path.open('w') {|f| f.write <<-STR }
      throw __FILE__.to_sym
    STR
    script = Script.new(path)
    assert_throws(path.to_s.to_sym) { script.parse! }
  end

  test "reloads script file" do
    @script.expects(:parse!)
    @script.ec.reload
  end

  test "skips parsing on nil script file" do
    script = Script.new
    script.ec.stubs(:instance_eval).raises(Exception) #negative expectation hack
    script.parse!
  end

  test "resets state" do
    @script.default_action { 'x' }
    @script.watch('foo') { 'bar' }
    @script.reset
    assert_nil @script.default_action.call
    assert_equal [], @script.rules
  end

  test "resets state on parse" do
    script = Script.new( Pathname( Tempfile.new('foo').path ) )
    script.stubs(:instance_eval)
    script.expects(:reset)
    script.parse!
  end

  test "actions receive a MatchData object" do
    @script.watch('de(.)') {|m| [m[0], m[1]] }
    assert_equal %w( def f ), @script.action_for('def').call
  end

  test "rule's default action" do
    @script.watch('abc')
    assert_nil @script.action_for('abc').call

    @script.default_action { :x }
    @script.watch('def')
    assert_equal :x, @script.action_for('def').call
  end

  test "file path" do
    Script.any_instance.stubs(:parse!)
    path   = Pathname('some/file').expand_path
    script = Script.new(path)
    assert_equal path, script.path
  end

  test "nil file path" do
    script = Script.new
    assert_nil script.path
  end

  test "later rules take precedence" do
    @script.watch('a/(.*)\.x')   { :x }
    @script.watch('a/b/(.*)\.x') { :y }
    assert_equal :y, @script.action_for('a/b/c.x').call
  end

  test "rule patterns match against paths relative to pwd" do
    @script.watch('^abc') { :x }
    path = Pathname(Dir.pwd) + 'abc'
    assert_equal :x, @script.action_for(path).call
  end
end
