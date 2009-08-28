module Watchr
  class Controller

    def initialize(script, handler = PortableEventHandler.new)
      @script  = script
      @handler = handler
      @handler.add_observer(self)
    end

    def run
      @handler.listen(observed_paths)
    end

    def observed_paths
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
    def update(path, event = nil)
      path = Pathname(path.to_s)

      if path.expand_path.to_s == @script.path.expand_path.to_s
        @script.parse!
      else
        @script.action_for(path).call
      end
    end
  end
end

