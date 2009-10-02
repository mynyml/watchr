require 'test/test_helper'

class PortableEventHandlerTest < Test::Unit::TestCase
  include Watchr

  def setup
    @handler = EventHandler::Portable.new
    @handler.stubs(:loop)

    @foo = Pathname('foo').expand_path
    @bar = Pathname('bar').expand_path
    @baz = Pathname('baz').expand_path
    @bax = Pathname('bax').expand_path

    @foo.stubs(:mtime).returns(Time.now - 100)
    @bar.stubs(:mtime).returns(Time.now - 100)
    @baz.stubs(:mtime).returns(Time.now - 100)
    @bax.stubs(:mtime).returns(Time.now - 100)
  end

  test "triggers listening state" do
    @handler.expects(:loop)
    @handler.listen([])
  end

  ## monitoring file events

  test "listens for events on monitored files" do
    @handler.listen [ @foo, @bar ]
    @handler.monitored_paths.should include(@foo)
    @handler.monitored_paths.should include(@bar)
  end

  test "notifies observers on file event" do
    @foo.stubs(:mtime).returns(Time.now + 100) # fake event

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :modified)
    @handler.trigger
  end

  test "doesn't trigger on start" do
  end

  ## on the fly updates of monitored files list

  test "reattaches to new monitored files" do
    @handler.listen [ @foo, @bar ]
    @handler.monitored_paths.should include(@foo)
    @handler.monitored_paths.should include(@bar)

    @handler.refresh [ @baz, @bax ]
    @handler.monitored_paths.should include(@baz)
    @handler.monitored_paths.should include(@bax)
    @handler.monitored_paths.should exclude(@foo)
    @handler.monitored_paths.should exclude(@bar)
  end
end
