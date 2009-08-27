module Watchr
  class Script
    attr_accessor :map
    attr_accessor :file
    attr_accessor :reference_time

    def initialize(file = nil)
      self.map  = []
      self.file = file.is_a?(Pathname) ? file : Pathname.new(file) unless file.nil?
      self.parse!
    end

    def watch(pattern, &action)
      a = block_given? ? action : @default_action
      self.map << [pattern, a]
    end

    def default_action(&action)
      @default_action = action
    end

    def changed?
      return false unless self.bound?
      self.file.mtime > self.reference_time
    end

    def parse!
      puts "[debug] loading script file #{self.file.to_s.inspect}" if Watchr.options.debug

      return false unless self.bound?
      self.map.clear
      self.instance_eval(self.file.read)
      self.reference_time = self.file.mtime
    end

    def bound?
      self.file && self.file.respond_to?(:exist?) && self.file.exist?
    end
  end
end
