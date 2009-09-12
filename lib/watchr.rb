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
  autoload :Script,     'watchr/script'
  autoload :Controller, 'watchr/controller'

  module EventHandler
    autoload :Base,     'watchr/event_handlers/base'
    autoload :Unix,     'watchr/event_handlers/unix'
    autoload :Portable, 'watchr/event_handlers/portable'
  end

  class << self
    attr_accessor :options
    attr_accessor :handler

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

    def handler
      @handler ||=
       #case ENV['HANDLER'] || RUBY_PLATFORM
        case ENV['HANDLER'] || Config::CONFIG['host_os']
          when /mswin|windows|cygwin/i
            Watchr::EventHandler::Portable
          when /bsd|sunos|solaris|darwin|osx|mach|linux/i, 'unix'
            Watchr::EventHandler::Unix
          else
            Watchr::EventHandler::Portable
        end
    end
  end
end
