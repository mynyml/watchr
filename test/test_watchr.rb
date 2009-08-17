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
end

class TestRunner < Test::Unit::TestCase
  include Watchr

  test "maps observed files to their pattern and the actions they trigger" do
    file_a = Fixture.create('a.rb')
    file_b = Fixture.create('b.rb')
    script = Script.new
    script.watch(file_a.pattern) { 'ohaie' }
    script.watch(file_b.pattern) { 'kthnx' }

    runner = Runner.new(script)
    runner.map[file_a.rel][0].should be(file_a.pattern)
    runner.map[file_b.rel][0].should be(file_b.pattern)
    runner.map[file_a.rel][1].call.should be('ohaie')
    runner.map[file_b.rel][1].call.should be('kthnx')
  end

  test "latest mtime" do
    file_a = Fixture.create('a.rb')
    file_b = Fixture.create('b.rb')
    script = Script.new
    script.watch(file_a.pattern) { 'ohaie' }
    script.watch(file_b.pattern) { 'kthnx' }

    runner = Runner.new(script)
    file_a.touch

    runner.last_updated_file.rel.should be(file_a.rel)
  end

  test "initial change state is true" do
    runner = Runner.new(Script.new)
    runner.changed?.should be(true)
  end

#  test "monitors file changes" do
#    file   = Fixture.create('a.rb')
#    script = Script.new
#    script.watch(file.pattern) { nil }
#
#    runner = Runner.new(script)
#    runner.changed?.should be(true)
#    sleep(2)
#    file.touch
#    runner.changed?.should be(true)
#  end

  test "calls action corresponding to file changed" do
    script = Script.new
    script.watch(Fixture.create.pattern) { throw(:ohaie) }

    runner = Runner.new(script)
    runner.changed?
    assert_throws(:ohaie) do
      runner.instance_eval { call_action! }
    end
  end

  test "passes match data to action" do
    file_a = Fixture.create('a.rb')
    script = Script.new
    pattern = File.join(Fixture::FIXDIR.rel, '(.*)\.(.*)$')
    script.watch((pattern)) {|md| [md[1], md[2]].join('|') }

    runner = Runner.new(script)
    runner.changed?
    runner.instance_eval { call_action! }.should be('a|rb')
  end

  test "a path only triggers its first matching pattern's action" do
  end
end
