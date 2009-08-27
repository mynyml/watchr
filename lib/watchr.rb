require 'pathname'

module Watchr
  LIBROOT = Pathname(__FILE__).dirname.parent
end

require Watchr::LIBROOT + 'lib/watchr/script'
require Watchr::LIBROOT + 'lib/watchr/runner'
require Watchr::LIBROOT + 'lib/watchr/fsevents'

module Watchr
  class << self
    attr_accessor :options

    def options
      @options ||= Struct.new(:debug).new
      # set default options
      @options.debug ||= false
      @options
    end
  end
end
