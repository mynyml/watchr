module Watchr
  class SingleFileWatcher < Rev::StatWatcher
    class << self
      attr_accessor :controller
    end
    def on_change
      self.class.controller.update(path, :changed)
    end
  end

  class Controller
    def initialize(script)
      @script = script
      SingleFileWatcher.controller = self
    end

    def run
      attach
      Rev::Loop.default.run
    end

    def update(path, event = nil)
      path = Pathname(path).expand_path

      if path == @script.path
        @script.parse!
        refresh
      else
        @script.action_for(path).call
      end
    end

    def monitored_paths
      paths = Dir['**/*'].select do |path|
        @script.patterns.any? {|p| path.match(p) }
      end
      paths.push(@script.path).compact!
      paths.map {|path| Pathname(path).expand_path }
    end

    def refresh
      detach
      attach
    end

    private

    def attach
      monitored_paths.each {|path| SingleFileWatcher.new(path.to_s).attach(Rev::Loop.default) }
    end

    def detach
      Rev::Loop.default.watchers.each {|watcher| watcher.detach }
    end
  end
end

