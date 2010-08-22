module Watchr
  module EventHandler

    class ::FSEvents
      # Same as Watch.debug, but prefixed with [fsevents] instead.
      #
      # @example
      #
      #     FSEvents.debug('missfired')
      #
      # @param [String] message
      #   debug message to print
      #
      # @return [nil]
      #
      def self.debug(msg)
        puts "[fsevents] #{msg}" if Watchr.options.debug
      end
    end

    # FSEvents based event handler for Darwin/OSX
    #
    # Uses ruby-fsevents (http://github.com/sandro/ruby-fsevent)
    #
    class Darwin < FSEvent
      include Base

      def initialize
        super
        self.latency = 0.2
      end

      # Enter listening loop. Will block control flow until application is
      # explicitly stopped/killed.
      #
      # @return [undefined]
      #
      def listen(monitored_paths)
        register_paths(monitored_paths)
        start
      end

      # Rebuild file bindings. Will detach all current bindings, and reattach
      # the `monitored_paths`
      #
      # @param [Array<Pathname>] monitored_paths
      #   list of paths the application is currently monitoring.
      #
      # @return [undefined]
      #
      def refresh(monitored_paths)
        register_paths(monitored_paths)
        restart
      end

      private

        # Callback. Called on file change event. Delegates to
        # {Controller#update}, passing in path and event type
        #
        # @return [undefined]
        #
        def on_change(dirs)
          dirs.each do |dir|
            path, type = detect_change(dir)
            notify(path, type) unless path.nil?
          end
        end

        # Detected latest updated file within given directory
        #
        # @param [Pathname, String] dir
        #   directory reporting event
        #
        # @return [Array(Pathname, Symbol)] path and type
        #   path to updated file and event type
        #
        def detect_change(dir)
          paths = monitored_paths_for(dir)
          type  = nil
          path  = paths.find {|path| type = event_type(path) }

          FSEvents.debug("event detection error") if type.nil?

          update_reference_times
          [path, type]
        end

        # Detect type of event for path, if any
        #
        # Path times (atime, mtime, ctime) are compared to stored references.
        # If any is more recent, the event is reported as a symbol.
        #
        # @param [Pathname] path
        #
        # @return [Symbol, nil] event type
        #   Event type if detected, nil otherwise.
        #   Symbol is on of :deleted, :modified, :accessed, :changed
        #
        def event_type(path)
          return :deleted   if !path.exist?
          return :modified  if  path.mtime > @reference_times[path][:mtime]
          return :accessed  if  path.atime > @reference_times[path][:atime]
          return :changed   if  path.ctime > @reference_times[path][:ctime]
          nil
        end

        # Monitored paths within given dir
        #
        # @param [Pathname, String] dir
        #
        # @return [Array<Pathname>] monitored_paths
        #
        def monitored_paths_for(dir)
          dir = Pathname(dir).expand_path
          @paths.select {|path| path.dirname.expand_path == dir }
        end

        # Register watches for paths
        #
        # @param [Array<Pathname>] paths
        #
        # @return [undefined]
        #
        def register_paths(paths)
          @paths = paths
          watch_directories(dirs_for(@paths))
          update_reference_times
        end

        # Directories for paths
        #
        # A unique list of directories containing given paths
        #
        # @param [Array<Pathname>] paths
        #
        # @return [Array<Pathname>] dirs
        #
        def dirs_for(paths)
          paths.map {|path| path.dirname.to_s }.uniq
        end

        # Update reference times for registered paths
        #
        # @return [undefined]
        #
        def update_reference_times
          @reference_times = {}
          now = Time.now
          @paths.each do |path|
            @reference_times[path] = {}
            @reference_times[path][:atime] = now
            @reference_times[path][:mtime] = now
            @reference_times[path][:ctime] = now
          end
        end
    end
  end
end

