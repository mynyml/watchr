module Watchr
  class Controller

    def initialize(script, handler = PortableEventHandler.new)
      @script  = script
      @handler = handler
      @handler.add_observer(self)
    end

    def run
      @handler.monitored_paths = monitored_paths
      @handler.listen
    end

    def monitored_paths
      Dir['**/*'].select do |path|
        @script.patterns.any? {|p| path.match(p) }
      end.
        push @script.path.to_s
    end

    # callback
    #
    # @see EventHandler#notify
    # @see corelib, Observable
    #
    # TODO handle event types.
    # TODO build array of recognied event types.
    #
    #   Controller.event_types = [:changed, :moved, :deleted, etc]
    #
    def update(path, event = nil)
      path = Pathname(path)

      if path.expand_path.to_s == @script.path.expand_path.to_s
        @script.parse!
      else
        @script.action_for(path).call
      end
    end
  end
end

