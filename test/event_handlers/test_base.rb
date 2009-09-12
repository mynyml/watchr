require 'test/test_helper'

class BaseEventHandlerTest < Test::Unit::TestCase

  class Handler
    include Watchr::EventHandler::Base
  end

  def setup
    @handler = Handler.new
  end

  test "api" do
    @handler.should respond_to(:notify)
    @handler.should respond_to(:listen)
    @handler.should respond_to(:refresh)
    @handler.class.ancestors.should include(Observable)
  end

  test "notifies observers" do
    @handler.expects(:notify_observers).with('foo/bar', nil)
    @handler.notify('foo/bar', nil)
  end
end
