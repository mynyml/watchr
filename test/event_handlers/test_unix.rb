require 'test/test_helper'
require 'eventmachine'

module EM #alias for EventMachine
  class << self
    def run(&block)
      block.call
    end
    def next_tick(&block)
      block.call
    end
    def watch_file(path, handler, *args)
      watcher = handler.new(:dummy, *args)
      watcher.instance_variable_set(:@path, path)
      watcher
    end
  end
end

class Watchr::EventHandler::Unix
  attr_accessor :watchers
end

class UnixEventHandlerTest < Test::Unit::TestCase
  include Watchr

  SingleFileWatcher = EventHandler::Unix::SingleFileWatcher

  def setup
    @handler = EventHandler::Unix.new
    SingleFileWatcher.any_instance.stubs(:stop_watching)
  end

  test "triggers listening state" do
    EM.expects(:run)
    @handler.listen([])
  end

  ## monitoring file events

  test "listens for events on monitored files" do
    @handler.listen %w( foo bar )
    @handler.watchers.size.should be(2)
    @handler.watchers.every.path.should include('foo')
    @handler.watchers.every.path.should include('bar')
  end

  test "notifies observers on file event" do
    watcher = SingleFileWatcher.new(:dummy, @handler)
    watcher.stubs(:path).returns('foo/bar')

    @handler.expects(:notify).with('foo/bar', :changed)
    watcher.file_modified
  end

  ## on the fly updates of monitored files list

  test "attaches new monitored files" do
    @handler.listen %w( foo bar )
    @handler.watchers.size.should be(2)
    @handler.watchers.every.path.should include('foo')
    @handler.watchers.every.path.should include('bar')

    SingleFileWatcher.any_instance.expects(:stop_watching).twice

    @handler.refresh %w( baz bax )
    @handler.watchers.size.should be(2)
    @handler.watchers.every.path.should include('baz')
    @handler.watchers.every.path.should include('bax')
    @handler.watchers.every.path.should exclude('foo')
    @handler.watchers.every.path.should exclude('bar')
  end
end
