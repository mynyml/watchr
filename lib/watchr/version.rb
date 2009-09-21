module Watchr
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 5
    TINY  = 4
  end

  def self.version #:nodoc:
    [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join('.')
  end
end
