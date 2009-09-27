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
    capture_io { Watchr.debug('abc') }.stdout.should be('')
    Watchr.options.debug = true
    capture_io { Watchr.debug('abc') }.stdout.should be("[watchr debug] abc\n")
  end

  test "picking handler" do

    Watchr.handler = nil
    ENV['HANDLER'] = 'linux'
    Watchr.handler.should be(Watchr::HAVE_REV ? Watchr::EventHandler::Unix : Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'bsd'
    Watchr.handler.should be(Watchr::HAVE_REV ? Watchr::EventHandler::Unix : Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'darwin'
    Watchr.handler.should be(Watchr::HAVE_REV ? Watchr::EventHandler::Unix : Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'unix'
    Watchr.handler.should be(Watchr::HAVE_REV ? Watchr::EventHandler::Unix : Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'mswin'
    Watchr.handler.should be(Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'cygwin'
    Watchr.handler.should be(Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'portable'
    Watchr.handler.should be(Watchr::EventHandler::Portable)

    Watchr.handler = nil
    ENV['HANDLER'] = 'other'
    Watchr.handler.should be(Watchr::EventHandler::Portable)
  end
end

