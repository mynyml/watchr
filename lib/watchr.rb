require 'pathname'
require 'rbconfig'

# Agile development tool that monitors a directory recursively, and triggers a
# user defined action whenever an observed file is modified. Its most typical
# use is continuous testing.
#
# See README for more details
#
# @example
#
#     # on command line, from project's root dir
#     $ watchr path/to/script
#
$LOAD_PATH.unshift(File.dirname(__FILE__))
module Watchr
  VERSION = '0.7'

  begin
    require 'fsevent'
    HAVE_FSE = true
  rescue LoadError, RuntimeError
    HAVE_FSE = false
  end

  begin
    require 'coolio'
    HAVE_COOLIO = true
  rescue LoadError, RuntimeError
    HAVE_COOLIO = false
  end

  autoload :Script,     'watchr/script'
  autoload :Controller, 'watchr/controller'

  module EventHandler
    autoload :Base,     'watchr/event_handlers/base'
    autoload :Portable, 'watchr/event_handlers/portable'
    autoload :Unix,     'watchr/event_handlers/unix'      if ::Watchr::HAVE_COOLIO
    autoload :Darwin,   'watchr/event_handlers/darwin'    if ::Watchr::HAVE_FSE
  end

  class << self
    attr_accessor :options
    attr_accessor :handler

    # @deprecated
    def version #:nodoc:
      Watchr::VERSION
    end

    # Options proxy.
    #
    # Currently supported options:
    #
    # * debug[Boolean] Debugging state. More verbose.
    #
    # @example
    #
    #     Watchr.options.debug #=> false
    #     Watchr.options.debug = true
    #
    # @return [Struct]
    #   options proxy.
    #
    def options
      @options ||= Struct.new(:debug).new
      @options.debug ||= false
      @options
    end

    # Outputs formatted debug statement to stdout, only if `::options.debug` is true
    #
    # @example
    #
    #     Watchr.options.debug = true
    #     Watchr.debug('im in ur codes, notifayinin u')
    #
    #     #outputs: "[watchr debug] im in ur codes, notifayinin u"
    #
    # @param [String] message
    #   debug message to print
    #
    # @return [nil]
    #
    def debug(msg)
      puts "[watchr debug] #{msg}" if options.debug
    end

    # Detect current OS and return appropriate handler.
    #
    # @example
    #
    #     Config::CONFIG['host_os'] #=> 'linux-gnu'
    #     Watchr.handler #=> Watchr::EventHandler::Unix
    #
    #     Config::CONFIG['host_os'] #=> 'cygwin'
    #     Watchr.handler #=> Watchr::EventHandler::Portable
    #
    #     ENV['HANDLER'] #=> 'unix'
    #     Watchr.handler #=> Watchr::EventHandler::Unix
    #
    #     ENV['HANDLER'] #=> 'portable'
    #     Watchr.handler #=> Watchr::EventHandler::Portable
    #
    # @return [Class]
    #   handler class for current architecture
    #
    def handler
      @handler ||=
        case ENV['HANDLER'] || Config::CONFIG['host_os']
          when /darwin|mach|osx|fsevents?/i
            if Watchr::HAVE_FSE
              Watchr::EventHandler::Darwin
            else
              Watchr.debug "fsevent not found. `gem install ruby-fsevent` to get evented handler"
              Watchr::EventHandler::Portable
            end
          when /sunos|solaris|bsd|linux|unix/i
            if Watchr::HAVE_COOLIO
              Watchr::EventHandler::Unix
            else
              Watchr.debug "coolio not found. `gem install coolio` to get evented handler"
              Watchr::EventHandler::Portable
            end
          when /mswin|windows|cygwin/i
            Watchr::EventHandler::Portable
          else
            Watchr::EventHandler::Portable
        end
    end
  end
end
