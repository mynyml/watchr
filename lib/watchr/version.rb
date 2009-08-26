module Watchr
  module VERSION
    MAJOR = 0
    MINOR = 3
    TINY  = 0
  end

  def self.version
    [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join('.')
  end
end
