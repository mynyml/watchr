require 'rev'

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


__END__
module Watchr
  class Controller

    def initialize(script, handler = Watchr.event_handler.new)
      @script  = script
      @handler = handler
      @handler.add_observer(self)
    end

    def run
      @handler.listen(monitored_paths)
    end

    def monitored_paths
      paths = Dir['**/*'].select do |path|
        @script.patterns.any? {|p| path.match(p) }
      end
      paths.push(@script.path).compact!
      paths.map {|path| Pathname(path).expand_path }
    end

    # EventHandler callback
    #
    # @see EventHandler#notify
    #
    # TODO handle event types.
    # TODO build array of recognized event types.
    #
    #   Controller.event_types = [:changed, :moved, :deleted, etc]
    #
    def update(path, event = nil)
      path = Pathname(path).expand_path

      if path == @script.path
        @script.parse!
        @handler.refresh(monitored_paths)
      else
        @script.action_for(path).call
      end
    end
  end
end

