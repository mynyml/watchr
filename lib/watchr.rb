require 'pathname'
require 'rbconfig'

require 'rev'

require 'watchr/core_ext/pathname'
require 'watchr/script'
require 'watchr/controller'

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
  end
end
