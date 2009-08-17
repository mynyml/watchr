module Watchr
  class Script
    attr_accessor :map

    def initialize(&block)
      self.map = []
    end

    def watch(pattern, &action)
      a = block_given? ? action : @default_action
      self.map << [pattern, a]
    end

    def default_action(&action)
      @default_action = action
    end
  end

  class Runner
    attr_accessor :script
    attr_accessor :map
    attr_accessor :reference_mtime
    attr_accessor :reference_file

    def initialize(script)
      self.script= script
    end

    def paths
      self.map.keys
    end

    def last_updated_file
      path = self.paths.max {|a,b| File.mtime(a) <=> File.mtime(b) }
      Pathname(path)
    end

    def changed?
      return true if self.paths.empty?

      last = self.last_updated_file
      if self.reference_mtime.nil? || self.reference_mtime.to_f < last.mtime.to_f
         self.reference_mtime = last.mtime
         self.reference_file  = last
         true
      else
         false
      end
    end

    def run
      loop do
        call_action! if changed?
        sleep(1)
      end
    end

    def map
      @map || map!
    end

    private

      def call_action!
        ref = self.reference_file.to_s
        pattern, action = self.map[ref]
        md = ref.match(pattern)
        action.call(md)
      end

      def map!
        @map = {}
        local_files.each do |path|
          patterns = self.script.map.map {|mapping| mapping[0] }
          patterns.each do |pattern|
            if path.match(pattern)
              action = self.script.map.assoc(pattern)[1]
              @map[path] = [pattern, action]
              #@map[path] = Struct.new(:pattern, :action).new(pattern, action)
            end
          end
        end
        @map
      end

      def local_files
        Dir['**/*']
      end
  end
end
