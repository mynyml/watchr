#!/usr/bin/env ruby

require 'pathname'
require 'optparse'
require 'tempfile'

require File.dirname(__FILE__) + '/../lib/watchr'

module Watchr
  # Namespaced to avoid defining global methods
  #
  # @private
  module Bin
    extend self

    DEFAULT_SCRIPT_PATH = Pathname.new('specs.watchr')

    attr_accessor :path

    def usage
      "Usage: watchr [opts] path/to/script"
    end

    def version
      "watchr version: %s" % Watchr::VERSION
    end

    # Absolute path to script file
    #
    # Unless set manually, the script's path is either first arg or
    # `DEFAULT_SCRIPT_PATH`. If neither exists, the script immediatly aborts
    # with an appropriate error message.
    #
    # @return [Pathname]
    #   absolute path to script
    #
    def path!
      return @path unless @path.nil?
      rel = relative_path    or abort( usage )
      find_in_load_path(rel) or abort("no script found: file #{rel.to_s.inspect} is not in path.")
    end

    # Find a partial path name in load path
    #
    # @param [Pathname] path
    #   partial pathname
    #
    # @return [Pathname]
    #   absolute path of first occurence of partial path in load path, or nil if not found
    #
    def find_in_load_path(path)
      # Adds '.' for ruby1.9.2
      dir = (['.'] + $LOAD_PATH).uniq.detect {|p| Pathname(p).join(path).exist? }
      dir ? path.expand_path(dir) : nil
    end

    private

    def relative_path
      return Pathname.new(ARGV.first) if ARGV.first
      return DEFAULT_SCRIPT_PATH      if DEFAULT_SCRIPT_PATH.exist?
    end
  end
end

opts = OptionParser.new do |opts|
  opts.banner = Watchr::Bin.usage

  opts.on('-d', '--debug', "Print extra debug info while program runs") {
    Watchr.options.debug = true
    begin
      require 'ruby-debug'
    rescue LoadError, RuntimeError
    end
  }
  opts.on('-l', '--list', "Display list of files monitored by script and exit") {
    script     = Watchr::Script.new(Watchr::Bin.path!)
    controller = Watchr::Controller.new(script, Watchr.handler.new)
    script.parse!
    puts controller.monitored_paths
    exit
  }

  def assert_syntax(code)
    catch(:ok) { Object.new.instance_eval("BEGIN { throw :ok }; #{code}", %|-e "#{code}"|, 0) }
  rescue SyntaxError => e
    puts e.message.split("\n")[1]
    exit
  end

  opts.on('-e', '--eval INLINE_SCRIPT', %|Evaluate script inline ($ watchr -e "watch('foo') { puts 'bar' }")|) {|code|
    assert_syntax(code)

    Tempfile.open('foo') {|f| f << code; @__path = f.path }
    Watchr::Bin.path = Pathname(@__path)
  }

  opts.on_tail('-h', '--help', "Print inline help") { puts opts; exit }
  opts.on_tail('-v', '--version', "Print version" ) { puts Watchr::Bin.version; exit }

  opts.parse! ARGV
end

Watchr::Controller.new(Watchr::Script.new(Watchr::Bin.path!), Watchr.handler.new).run

