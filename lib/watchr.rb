require 'pathname'
require 'rbconfig'

module Watchr
  ROOT = Pathname(__FILE__).dirname.parent
end

require Watchr::ROOT + 'lib/core_ext/pathname'

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

  autoload :Script,     ( ROOT/'lib/watchr/script'     ).to_s
  autoload :Controller, ( ROOT/'lib/watchr/controller' ).to_s
  end
end
