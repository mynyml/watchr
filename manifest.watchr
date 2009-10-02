# Run me with:
#
#   $ watchr manifest.watchr
#
# This script will remove a file from from the Manifest when it gets deleted,
# and will rebuild the Manifest on Ctrl-\
#
# Mostly serves as a demo for the :delete event type (and eventually for the
# :added event type). In reality this is much better implemented as a git
# post-commit script.
#

require 'pathname'
# --------------------------------------------------
# Helpers
# --------------------------------------------------
module Project
  extend self
  def files
    `git ls-files --full-name`.strip.split($/).sort
  end
end

class Manifest
  attr_accessor :path

  def initialize(path)
    @path = Pathname(path).expand_path
    create!
  end

  def remove(path)
    paths = @path.read.strip.split($/)
    @path.open('w') {|f| f << (paths - [path]).join("\n") }
  end

  def add(path)
    paths = @path.read.strip.split($/)
    @path.open('w') {|f| f << paths.push(path).sort.join("\n") }
  end

  private
  def create!
    File.open(@path.to_s, 'w') {} unless @path.exist?
  end
end


@manifest = Manifest.new('Manifest')

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch('.*', :deleted ) do |md|
  @manifest.remove(md[0])
  puts "removed #{md[0].inspect} from Manifest"
end

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Updated Manifest ---\n"
  @manifest.path.open('w') {|m| m << Project.files.join("\n").strip }
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }

