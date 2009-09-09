module Watchr

  # Used by Rev. Wraps a monitored path, and Rev::Loop will call its callback
  # on file events.
  class SingleFileWatcher < Rev::StatWatcher #:nodoc:
    class << self
      # Stores a reference back to controller so we can call its #update method
      # with file event info
      attr_accessor :controller
    end

    # Callback. Called on file change event
    # Delegates to Controller#update, passing in path and event type
    def on_change
      self.class.controller.update(path, :changed)
    end
  end

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
    def initialize(script)
      @script = script
      SingleFileWatcher.controller = self
    end

    # Enters listening loop.
    #
    # Will block control flow until application is explicitly stopped/killed.
    #
    def run
      attach
      Rev::Loop.default.run
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
    def update(path, event = nil)
      path = Pathname(path).expand_path

      if path == @script.path
        @script.parse!
        refresh
      else
        @script.action_for(path).call
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

    # Rebuilds file bindings.
    #
    # Will detach all current bindings, and reattach the <tt>monitored_paths</tt>
    #
    # see:: #attach
    # see:: #detach
    # see:: #monitored_paths
    #
    def refresh
      detach
      attach
    end

    private

    # Binds all <tt>monitored_paths</tt> to the listening loop.
    def attach
      monitored_paths.each {|path| SingleFileWatcher.new(path.to_s).attach(Rev::Loop.default) }
    end

    # Unbinds all paths currently attached to listening loop.
    def detach
      Rev::Loop.default.watchers.each {|watcher| watcher.detach }
    end
  end
end

