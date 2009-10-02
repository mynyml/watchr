module Watchr

  # The controller contains the app's core logic.
  #
  # ===== Examples
  #
  #   script = Watchr::Script.new(file)
  #   contrl = Watchr::Controller.new(script)
  #   contrl.run
  #
  # Calling <tt>#run</tt> will enter the listening loop, and from then on every
  # file event will trigger its corresponding action defined in <tt>script</tt>
  #
  # The controller also automatically adds the script's file itself to its list
  # of monitored files and will detect any changes to it, providing on the fly
  # updates of defined rules.
  #
  class Controller

    # Creates a controller object around given <tt>script</tt>
    #
    # ===== Parameters
    # script<Script>:: The script object
    #
    def initialize(script, handler)
      @script  = script
      @handler = handler
      @handler.add_observer(self)

      Watchr.debug "using %s handler" % handler.class.name
    end

    # Enters listening loop.
    #
    # Will block control flow until application is explicitly stopped/killed.
    #
    def run
      @handler.listen(monitored_paths)
    end

    # Callback for file events.
    #
    # Called while control flow in in listening loop. It will execute the
    # file's corresponding action as defined in the script. If the file is the
    # script itself, it will refresh its state to account for potential changes.
    #
    # ===== Parameters
    # path<Pathname, String>:: path that triggered event
    # event<Symbol>:: event type (ignored for now)
    #
    def update(path, event_type = nil)
      path = Pathname(path).expand_path

      if path == @script.path
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
    # ===== Returns
    # paths<Array[Pathname]>:: List of monitored paths
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

