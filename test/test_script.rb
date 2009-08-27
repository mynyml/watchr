require 'test/test_helper'

class TestScript < Test::Unit::TestCase
  include Watchr

  ## api

  test "watch" do
    script = Script.new
    script.watch('pattern') { nil }

    script.map.first[0].should be('pattern')
    script.map.first[1].call.should be(nil)
  end

  test "default action" do
    script = Script.new
    script.default_action { nil }
    script.watch('pattern')

    script.map.first[0].should be('pattern')
    script.map.first[1].call.should be(nil)
  end

  test "automatically picks up changes to script file" do
    file = Fixture.create('script.watchr', "watch('abc')")
    script = Script.new(file)
    script.changed?.should be(false)

    script.stubs(:reference_time).returns(Time.now - 10) #mock sleep

    Fixture.create('script.watchr', "watch('def')")
    script.changed?.should be(true)
  end

  test "reparses script file" do
    file   = Fixture.create('script.watchr', "watch('abc')")
    script = Script.new(file)
    script.map.first.should include('abc')
    script.map.first.should exclude('def')

    script.stubs(:reference_time).returns(Time.now - 10) #mock sleep
    Fixture.create('script.watchr', "watch('def')")
    script.parse!
    script.map.first.should include('def')
    script.map.first.should exclude('abc')
  end
end
