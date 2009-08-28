require 'test/test_helper'

class TestWatchr < Test::Unit::TestCase

  def setup
    Watchr.options = nil
  end

  ## options

  test "debug option" do
    Watchr.options.debug.should be(false)
    Watchr.options.debug = true
    Watchr.options.debug.should be(true)
  end

  ## functionality

  test "debug" do
    capture_io { Watchr.debug('abc') }.first.should be('')
    Watchr.options.debug = true
    capture_io { Watchr.debug('abc') }.first.should be("[debug] abc\n")
  end
end


