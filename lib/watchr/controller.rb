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
        @handler.refresh
      else
        @script.action_for(path).call
      end
    end
  end
end

