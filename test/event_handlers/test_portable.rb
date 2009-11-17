require 'test/test_helper'

class Watchr::EventHandler::Portable
  attr_accessor :monitored_paths
end

class PortableEventHandlerTest < MiniTest::Unit::TestCase
  include Watchr

  def setup
    @handler = EventHandler::Portable.new
    @handler.stubs(:loop)

    @foo = Pathname('foo').expand_path
    @bar = Pathname('bar').expand_path
    @baz = Pathname('baz').expand_path
    @bax = Pathname('bax').expand_path

    @now = Time.now
    [@foo, @bar, @baz, @bax].each do |path|
      path.stubs(:mtime ).returns(@now - 100)
      path.stubs(:atime ).returns(@now - 100)
      path.stubs(:ctime ).returns(@now - 100)
      path.stubs(:exist?).returns(true)
    end
  end

  test "triggers listening state" do
    @handler.expects(:loop)
    @handler.listen([])
  end

  ## monitoring file events

  test "listens for events on monitored files" do
    @handler.listen [ @foo, @bar ]
    assert_includes @handler.monitored_paths, @foo
    assert_includes @handler.monitored_paths, @bar
  end

  test "doesn't trigger on start" do
  end

  ## event types

  test "deleted file event" do
    @foo.stubs(:exist?).returns(false)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :deleted)
    @handler.trigger
  end

  test "modified file event" do
    @foo.stubs(:mtime).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :modified)
    @handler.trigger
  end

  test "accessed file event" do
    @foo.stubs(:atime).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :accessed)
    @handler.trigger
  end

  test "changed file event" do
    @foo.stubs(:ctime).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :changed)
    @handler.trigger
  end

  ## event type priorities

  test "mtime > atime" do
    @foo.stubs(:mtime).returns(@now + 100)
    @foo.stubs(:atime).returns(@now + 100)
    @foo.stubs(:ctime).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :modified)
    @handler.trigger
  end

  test "mtime > ctime" do
    @foo.stubs(:mtime).returns(@now + 100)
    @foo.stubs(:ctime).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :modified)
    @handler.trigger
  end

  test "atime > ctime" do
    @foo.stubs(:atime).returns(@now + 100)
    @foo.stubs(:ctime).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :accessed)
    @handler.trigger
  end

  test "deleted > mtime" do
    @foo.stubs(:exist?).returns(false)
    @foo.stubs(:mtime ).returns(@now + 100)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :deleted)
    @handler.trigger
  end

  ## on the fly updates of monitored files list

  test "reattaches to new monitored files" do
    @handler.listen [ @foo, @bar ]
    assert_includes @handler.monitored_paths, @foo
    assert_includes @handler.monitored_paths, @bar

    @handler.refresh [ @baz, @bax ]
    assert_includes @handler.monitored_paths, @baz
    assert_includes @handler.monitored_paths, @bax
    refute_includes @handler.monitored_paths, @foo
    refute_includes @handler.monitored_paths, @bar
  end

  test "retries on ENOENT errors" do
    @oops = Pathname('oops').expand_path
    @oops.stubs(:exist?).returns(true)
    @oops.stubs(:mtime).raises(Errno::ENOENT).
      then.returns(Time.now + 100)

    @handler.listen [ @oops ]

    @handler.expects(:notify).with(@oops, :modified)
    @handler.trigger
  end
end
