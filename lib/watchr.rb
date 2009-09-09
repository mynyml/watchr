require 'pathname'
require 'rbconfig'

require 'rev'

require 'watchr/core_ext/pathname'
require 'watchr/script'
require 'watchr/controller'

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
  class << self
    attr_accessor :options

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
  end
end
