require 'test/test_helper'

if Watchr::HAVE_FSE

class Watchr::EventHandler::Darwin
  attr_accessor :paths

  def start()   end #noop
  def restart() end #noop

  public :on_change, :registered_directories
end

class DarwinEventHandlerTest < MiniTest::Unit::TestCase
  include Watchr

  def tempfile(name)
    file = Tempfile.new(name, @root.to_s)
    Pathname(file.path)
  ensure
    file.close
  end

  def setup
    @root = Pathname(Dir.mktmpdir("WATCHR_SPECS-"))

    @now = Time.now
    @handler = EventHandler::Darwin.new

    @foo = tempfile('foo').expand_path
    @bar = tempfile('bar').expand_path
  end

  def teardown
    FileUtils.remove_entry_secure(@root.to_s)
  end

  test "listening triggers listening state" do
    @handler.expects(:start)
    @handler.listen([])
  end

  test "listens for events on monitored files" do
    @handler.listen [ @foo, @bar ]
    assert_includes @handler.paths, @foo
    assert_includes @handler.paths, @bar
  end

  test "reattaches to new monitored files" do
    @baz = tempfile('baz').expand_path
    @bax = tempfile('bax').expand_path

    @handler.listen [ @foo, @bar ]
    assert_includes @handler.paths, @foo
    assert_includes @handler.paths, @bar

    @handler.refresh [ @baz, @bax ]
    assert_includes @handler.paths, @baz
    assert_includes @handler.paths, @bax
    refute_includes @handler.paths, @foo
    refute_includes @handler.paths, @bar
  end

  ## event types

  test "deleted file event" do
    @foo.stubs(:exist?).returns(false)

    @handler.listen [ @foo, @bar ]
    @handler.expects(:notify).with(@foo, :deleted)
    @handler.on_change [@root]
  end

  test "modified file event" do
    @foo.stubs(:mtime).returns(@now + 100)
    @handler.expects(:notify).with(@foo, :modified)

    @handler.listen [ @foo, @bar ]
    @handler.on_change [@root]
  end

  test "accessed file event" do
    @foo.stubs(:atime).returns(@now + 100)
    @handler.expects(:notify).with(@foo, :accessed)

    @handler.listen [ @foo, @bar ]
    @handler.on_change [@root]
  end

  test "changed file event" do
    @foo.stubs(:ctime).returns(@now + 100)
    @handler.expects(:notify).with(@foo, :changed)

    @handler.listen [ @foo, @bar ]
    @handler.on_change [@root]
  end

  ## internal

  test "registers directories" do
    @handler.listen [ @foo, @bar ]

    assert_equal @foo.dirname, @bar.dirname # make sure all tempfiles are in same dir
    assert_equal 1, @handler.registered_directories.size
    assert_includes @handler.registered_directories, @foo.dirname.to_s
    assert_includes @handler.registered_directories, @bar.dirname.to_s
  end
end

end  # if Watchr::HAVE_FSE

