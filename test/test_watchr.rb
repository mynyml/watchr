require 'test/test_helper'

class TestWatchr < Test::Unit::TestCase

  def setup
    Watchr.options = nil
  end

  ## options

  test "debug" do
    Watchr.options.debug.should be(false)
    Watchr.options.debug = true
    Watchr.options.debug.should be(true)
  end
end


