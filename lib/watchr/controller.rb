module Watchr

  # The controller contains the app's core logic.
  #
  # @example
  #
  #     script = Watchr::Script.new(file)
  #     contrl = Watchr::Controller.new(script, Watchr.handler.new)
  #     contrl.run
  #
  #     # Calling `run` will enter the listening loop, and from then on every
  #     # file event will trigger its corresponding action defined in `script`
  #
  #     # The controller also automatically adds the script's file to its list of
  #     # monitored files and will detect any changes to it, providing on the fly
  #     # updates of defined rules.
  #
  class Controller

    # Create a controller object around given `script`
    #
    # @param [Script] script
    #   The script object
    #
    # @param [EventHandler::Base] handler
    #   The filesystem event handler
    #
    # @see Watchr::Script
    # @see Watchr.handler
    #
    def initialize(script, handler)
      @script, @handler = script, handler
      @handler.add_observer(self)

      Watchr.debug "using %s handler" % handler.class.name
    end

    # Enter listening loop. Will block control flow until application is
    # explicitly stopped/killed.
    def run
      @script.parse!
      @handler.listen(monitored_paths)
    rescue Interrupt
    end

    # Callback for file events
    #
    # Called while control flow is in listening loop. It will execute the
    # file's corresponding action as defined in the script. If the file is the
    # script itself, it will refresh its state to account for potential changes.
    #
    # @param [Pathname, String] path
    #   path that triggered the event
    #
    # @param [Symbol] event
    #   event type
    #
    def update(path, event_type = nil)
      path = Pathname(path).expand_path

      Watchr.debug("received #{event_type.inspect} event for #{path.relative_path_from(Pathname(Dir.pwd))}")
      if path == @script.path && (event_type != :accessed && event_type != :deleted)
        @script.parse!
        @handler.refresh(monitored_paths)
      else
        @script.action_for(path, event_type).call
      end
    end

    # List of paths the script is monitoring.
    #
    # Basically this means all paths below current directoly recursivelly that
    # match any of the rules' patterns, plus the script file.
    #
    # @return [Array<Pathname>]
    #   list of all monitored paths
    #
    def monitored_paths
      paths = Dir['**/*'].select do |path|
        @script.patterns.any? {|p| path.match(p) }
      end
      paths.push(@script.path).compact!
      paths.map {|path| Pathname(path).expand_path }
    end
  end
end

