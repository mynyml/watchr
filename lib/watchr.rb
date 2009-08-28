require 'pathname'

module Watchr
  ROOT = Pathname(__FILE__).dirname.parent

  class << self
    attr_accessor :options

    def options
      @options ||= Struct.new(:debug).new
      @options.debug ||= false
      @options
    end

    def debug(str)
      puts "[debug] #{str}" if options.debug
    end
  end

  autoload :Script,               ( ROOT + 'lib/watchr/script'                                ).to_s
  autoload :Controller,           ( ROOT + 'lib/watchr/controller'                            ).to_s
  autoload :AbstractEventHandler, ( ROOT + 'lib/watchr/event_handlers/abstract_event_handler' ).to_s
  autoload :PortableEventHandler, ( ROOT + 'lib/watchr/event_handlers/portable_event_handler' ).to_s
  autoload :LinuxEventHandler,    ( ROOT + 'lib/watchr/event_handlers/linux_event_handler'    ).to_s
end
