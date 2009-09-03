require 'pathname'
require 'rbconfig'

module Watchr
  ROOT = Pathname(__FILE__).dirname.parent
end

require Watchr::ROOT + 'lib/core_ext/pathname'
#require Watchr::ROOT + 'lib/core_ext/string'

module Watchr
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

    def event_handler
      @handler ||=
       #case ENV['HANDLER'] || RUBY_PLATFORM
        case ENV['HANDLER'] || Config::CONFIG['host_os']
          when /linux/i
            Watchr::EventHandler::Linux
          when /mswin|windows|cygwin/i
            Watchr::EventHandler::Windows
          when /sunos|solaris|darwin/i, 'unix'
            Watchr::EventHandler::Unix
          else
            Watchr::EventHandler::Portable
        end
    end
    alias :handler :event_handler
  end

  autoload :Script,     ( ROOT/'lib/watchr/script'     ).to_s
  autoload :Controller, ( ROOT/'lib/watchr/controller' ).to_s

  module EventHandler
    autoload :Base,     ( ROOT/'lib/watchr/event_handlers/base'     ).to_s
    autoload :Portable, ( ROOT/'lib/watchr/event_handlers/portable' ).to_s
    autoload :Linux,    ( ROOT/'lib/watchr/event_handlers/linux'    ).to_s
    autoload :Unix,     ( ROOT/'lib/watchr/event_handlers/unix'     ).to_s
  end
end
