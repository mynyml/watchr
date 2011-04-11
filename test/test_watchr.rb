require 'test/test_helper'

class TestWatchr < MiniTest::Unit::TestCase

  def setup
    Watchr.options = nil
  end

  ## options

  test "debug option" do
    assert_equal false, Watchr.options.debug
    Watchr.options.debug = true
    assert_equal true,  Watchr.options.debug
  end

  ## functionality

  test "debug" do
    assert_empty capture_io { Watchr.debug('abc') }.first
    Watchr.options.debug = true
    assert_equal "[watchr debug] abc\n", capture_io { Watchr.debug('abc') }.first
  end

  test "picking handler" do

    if Watchr::HAVE_COOLIO

    Watchr.handler = nil
    ENV['HANDLER'] = 'linux'
    assert_equal Watchr::EventHandler::Unix, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'bsd'
    assert_equal Watchr::EventHandler::Unix, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'unix'
    assert_equal Watchr::EventHandler::Unix, Watchr.handler

    end

    if Watchr::HAVE_FSE

    Watchr.handler = nil
    ENV['HANDLER'] = 'darwin'
    assert_equal Watchr::EventHandler::Darwin, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'osx'
    assert_equal Watchr::EventHandler::Darwin, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'fsevent'
    assert_equal Watchr::EventHandler::Darwin, Watchr.handler

    end

    Watchr.handler = nil
    ENV['HANDLER'] = 'mswin'
    assert_equal Watchr::EventHandler::Portable, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'cygwin'
    assert_equal Watchr::EventHandler::Portable, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'portable'
    assert_equal Watchr::EventHandler::Portable, Watchr.handler

    Watchr.handler = nil
    ENV['HANDLER'] = 'other'
    assert_equal Watchr::EventHandler::Portable, Watchr.handler
  end
end

