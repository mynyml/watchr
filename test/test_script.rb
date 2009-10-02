require 'test/test_helper'

class TestScript < Test::Unit::TestCase
  include Watchr

  def setup
    tmpfile = Tempfile.new('foo')
    @script = Script.new( Pathname.new( tmpfile.path ) )
  end

  ## external api

  test "watch" do
    @script.watch('pattern')
    @script.watch('pattern', :event_type)
    @script.watch('pattern') { nil }
  end

  test "default action" do
    @script.default_action { nil }
  end

  ## functionality

  test "rule object" do
    rule = @script.watch('pattern', :modified) { nil }
    rule.pattern.should be('pattern')
    rule.event_type.should be(:modified)
    rule.action.call.should be(nil)
  end

  test "default event type" do
    rule = @script.watch('pattern') { nil }
    rule.event_type.should be(:modified)
  end

  test "finds action for path" do
    @script.watch('abc') { :x }
    @script.watch('def') { :y }
    @script.action_for('abc').call.should be(:x)
  end

  test "finds action for path with event type" do
    @script.watch('abc', :accessed) { :x }
    @script.watch('abc', :modified) { :y }
    @script.action_for('abc', :accessed).call.should be(:x)
  end

  test "finds action for path with any event type" do
    @script.watch('abc', nil) { :x }
    @script.watch('abc', :modified) { :y }
    @script.action_for('abc', :accessed).call.should be(:x)
  end

  test "no action for path" do
    @script.watch('abc', :accessed) { :x }
    @script.action_for('abc', :modified).call.should be(nil)
  end

  test "collects patterns" do
    @script.watch('abc')
    @script.watch('def')
    @script.patterns.should include('abc')
    @script.patterns.should include('def')
  end

  test "parses script file" do
    file = Pathname( Tempfile.open('bar').path )
    file.open('w') {|f| f.write <<-STR }
      watch( 'abc' ) { :x }
    STR
    script = Script.new(file)
    script.action_for('abc').call.should be(:x)
  end

  test "resets state" do
    @script.default_action { 'x' }
    @script.watch('foo') { 'bar' }
    @script.send(:reset)
    @script.instance_variable_get(:@default_action).call.should be(nil)
    @script.instance_variable_get(:@rules).should be([])
  end

  test "resets state on parse" do
    @script.stubs(:instance_eval)
    @script.expects(:reset)
    @script.parse!
  end

  test "actions receive a MatchData object" do
    @script.watch('de(.)') {|m| [m[0], m[1]] }
    @script.action_for('def').call.should be(%w( def f ))
  end

  test "rule's default action" do
    @script.watch('abc')
    @script.action_for('abc').call.should be(nil)
    @script.default_action { :x }

    @script.watch('def')
    @script.action_for('def').call.should be(:x)
  end

  test "file path" do
    Script.any_instance.stubs(:parse!)
    path   = Pathname('some/file').expand_path
    script = Script.new(path)
    script.path.should be(path)
  end

  test "later rules take precedence" do
    @script.watch('a/(.*)\.x')   { :x }
    @script.watch('a/b/(.*)\.x') { :y }

    @script.action_for('a/b/c.x').call.should be(:y)
  end

  test "rule patterns match against paths relative to pwd" do
    @script.watch('^abc') { :x }
    path = Pathname(Dir.pwd) + 'abc'
    @script.action_for(path).call.should be(:x)
  end
end
