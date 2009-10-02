module Watchr
  module EventHandler
    class Unix
      include Base

      # Used by Rev. Wraps a monitored path, and Rev::Loop will call its
      # callback on file events.
      class SingleFileWatcher < Rev::StatWatcher #:nodoc:
        class << self
          # Stores a reference back to handler so we can call its #nofity
          # method with file event info
          attr_accessor :handler
        end

        def initialize(path)
          super
          update_reference_times
        end

        # File's path as a Pathname
        def pathname
          @pathname ||= Pathname(@path)
        end

        # Callback. Called on file change event
        # Delegates to Controller#update, passing in path and event type
        def on_change
          self.class.handler.notify(path, type)
          update_reference_times unless type == :deleted
        end

        private

        def update_reference_times
          @reference_atime = pathname.atime
          @reference_mtime = pathname.mtime
          @reference_ctime = pathname.ctime
        end

        # Type of latest event.
        #
        # A single type is determined, even though more than one stat times may
        # have changed on the file. The type is the first to match in the
        # following hierarchy:
        #
        #   :deleted, :modified (mtime), :accessed (atime), :changed (ctime)
        #
        # ===== Returns
        # type<Symbol>:: latest event's type
        #
        def type
          return :deleted   if !pathname.exist?
          return :modified  if  pathname.mtime > @reference_mtime
          return :accessed  if  pathname.atime > @reference_atime
          return :changed   if  pathname.ctime > @reference_ctime
        end
      end

      def initialize
        SingleFileWatcher.handler = self
        @loop = Rev::Loop.default
      end

      # Enters listening loop.
      #
      # Will block control flow until application is explicitly stopped/killed.
      #
      def listen(monitored_paths)
        @monitored_paths = monitored_paths
        attach
        @loop.run
      end

      # Rebuilds file bindings.
      #
      # will detach all current bindings, and reattach the <tt>monitored_paths</tt>
      #
      def refresh(monitored_paths)
        @monitored_paths = monitored_paths
        detach
        attach
      end

      private

      # Binds all <tt>monitored_paths</tt> to the listening loop.
      def attach
        @monitored_paths.each {|path| SingleFileWatcher.new(path.to_s).attach(@loop) }
      end

      # Unbinds all paths currently attached to listening loop.
      def detach
        @loop.watchers.each {|watcher| watcher.detach }
      end
    end
  end
end
