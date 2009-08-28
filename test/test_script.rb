require 'test/test_helper'

class TestScript < Test::Unit::TestCase
  include Watchr

  ## external api

  test "watch" do
    Script.new.watch('pattern')
    Script.new.watch('pattern') { nil }
  end

  test "default action" do
    Script.new.default_action { nil }
  end

  ## functionality

  test "finds action for path" do
    script = Script.new
    script.watch('abc') { :x }
    script.watch('def') { :y }
    script.action_for('abc').call.should be(:x)
  end

  test "parses script file" do
    file = StringIO.new(<<-STR)
      watch( 'abc' ) { :x }
    STR
    script = Script.new(file)
    script.action_for('abc').call.should be(:x)
  end

  test "actions receive a MatchData object" do
    script = Script.new
    script.watch('de(.)') {|m| [m[0], m[1]] }
    script.action_for('def').call.should be(%w( def f ))
  end

  test "rule's default action" do
    script = Script.new

    script.watch('abc')
    script.action_for('abc').call.should be(nil)
    script.default_action { :x }

    script.watch('def')
    script.action_for('def').call.should be(:x)
  end
end
