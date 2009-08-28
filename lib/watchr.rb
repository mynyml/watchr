require 'pathname'

module Watchr
  LIBROOT = Pathname(__FILE__).dirname.parent

  autoload :Script,       ( LIBROOT + 'lib/watchr/script'        ).to_s
  autoload :Controller,   ( LIBROOT + 'lib/watchr/controller'    ).to_s
  autoload :EventHandler, ( LIBROOT + 'lib/watchr/event_handler' ).to_s

  class << self
    attr_accessor :options

    def options
      @options ||= Struct.new(:debug).new
      # set default options
      @options.debug ||= false
      @options
    end

    def debug(str)
      puts "[debug] #{str}" if options.debug
    end
  end
end
