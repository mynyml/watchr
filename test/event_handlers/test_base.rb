require 'test/test_helper'

class BaseEventHandlerTest < MiniTest::Unit::TestCase

  class Handler
    include Watchr::EventHandler::Base
  end

  def setup
    @handler = Handler.new
  end

  test "api" do
    assert_respond_to @handler, :notify
    assert_respond_to @handler, :listen
    assert_respond_to @handler, :refresh
    assert_includes   @handler.class.ancestors, Observable
  end

  test "notifies observers" do
    @handler.expects(:notify_observers).with('foo/bar', nil)
    @handler.notify('foo/bar', nil)
  end
end
