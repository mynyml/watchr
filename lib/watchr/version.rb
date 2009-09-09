module Watchr
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 3
    TINY  = 0
  end

  def self.version #:nodoc:
    [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join('.')
  end
end
