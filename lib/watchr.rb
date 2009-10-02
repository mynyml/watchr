require 'pathname'
require 'rbconfig'

# Agile development tool that monitors a directory recursively, and triggers a
# user defined action whenever an observed file is modified. Its most typical
# use is continuous testing.
#
# Usage:
#
#   # on command line, from project's root dir
#   $ watchr path/to/script
#
# See README for more details
#
module Watchr
  VERSION = '0.5.7'

  begin
    require 'rev'
    HAVE_REV = true
  rescue LoadError, RuntimeError
    HAVE_REV = false
  end

  autoload :Script,     'watchr/script'
  autoload :Controller, 'watchr/controller'

  module EventHandler
    autoload :Base,     'watchr/event_handlers/base'
    autoload :Unix,     'watchr/event_handlers/unix' if ::Watchr::HAVE_REV
    autoload :Portable, 'watchr/event_handlers/portable'
  end

  class << self
    attr_accessor :options
    attr_accessor :handler

    # backwards compatibility
    def version #:nodoc:
      Watchr::VERSION
    end

    # Options proxy.
    #
    # Currently supported options:
    # * debug<Boolean> Debugging state. More verbose.
    #
    # ===== Examples
    #
    #   Watchr.options.debug #=> false
    #   Watchr.options.debug = true
    #
    # ===== Returns
    # options<Struct>:: options proxy.
    #
    #--
    # On first use, initialize the options struct and default option values.
    def options
      @options ||= Struct.new(:debug).new
      @options.debug ||= false
      @options
    end

    # Outputs formatted debug statement to stdout, only if ::options.debug is true
    #
    # ===== Examples
    #
    #   Watchr.options.debug = true
    #   Watchr.debug('im in ur codes, notifayinin u')
    #
    # outputs: "[watchr debug] im in ur codes, notifayinin u"
    #
    def debug(str)
      puts "[watchr debug] #{str}" if options.debug
    end

    # Detect current OS and return appropriate handler.
    #
    # ===== Examples
    #
    #   Config::CONFIG['host_os'] #=> 'linux-gnu'
    #   Watchr.handler #=> Watchr::EventHandler::Unix
    #
    #   Config::CONFIG['host_os'] #=> 'cygwin'
    #   Watchr.handler #=> Watchr::EventHandler::Portable
    #
    #   ENV['HANDLER'] #=> 'unix'
    #   Watchr.handler #=> Watchr::EventHandler::Unix
    #
    #   ENV['HANDLER'] #=> 'portable'
    #   Watchr.handler #=> Watchr::EventHandler::Portable
    #
    # ===== Returns
    # handler<Class>:: handler class for current architecture
    #
    def handler
      @handler ||=
        case ENV['HANDLER'] || Config::CONFIG['host_os']
          when /mswin|windows|cygwin/i
            Watchr::EventHandler::Portable
          when /sunos|solaris|darwin|mach|osx|bsd|linux/i, 'unix'
            if ::Watchr::HAVE_REV
              Watchr::EventHandler::Unix
            else
              Watchr.debug "rev not found. `gem install rev` to get evented handler"
              Watchr::EventHandler::Portable
            end
          else
            Watchr::EventHandler::Portable
        end
    end
  end
end
