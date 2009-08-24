module Watchr
  class Script
    attr_accessor :map

    def initialize(str = nil)
      self.map = []
      self.instance_eval(str) unless str.nil?
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
    attr_accessor :init_time
    attr_accessor :reference_file

    # Caches reference_file.mtime to allow picking up an update to the
    # reference file itself
    attr_accessor :reference_time

    def initialize(script)
      self.init_time = Time.now.to_f
      self.script = script
    end

    def paths
      self.map.keys
    end

    def last_updated_file
      path = self.paths.max {|a,b| File.mtime(a) <=> File.mtime(b) }
      Pathname(path)
    end

    def changed?
      return true  if self.paths.empty?
      return false if self.last_updated_file.mtime.to_f < self.init_time.to_f

      if self.reference_file.nil? || (self.reference_time.to_f < self.last_updated_file.mtime.to_f)
         self.reference_file  = self.last_updated_file
         self.reference_time  = self.last_updated_file.mtime
         true
      else
         false
      end
    end

    def run
      # enter monitoring state
      loop do
        call_action! if self.changed?
        sleep(1)
      end
    end

    def map
      @map || map!
    end

    private

      def call_action!
        raise "no reference file" if self.reference_file.nil?

        ref = self.reference_file.to_s
        pattern, action = self.map[ref]
        md = ref.match(pattern)
        action.call(md)
      end

      def map!
        @map = {}
        patterns = self.script.map.map {|mapping| mapping[0] }
        patterns.each do |pattern|
          local_files.each do |path|
            if path.match(pattern)
              action = self.script.map.assoc(pattern)[1]
              @map[path] = [pattern, action]
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
