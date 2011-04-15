module Watchr
  module EventHandler
    class Unix
      include Base

      # Used by Coolio. Wraps a monitored path, and `Coolio::Loop` will call its
      # callback on file events.
      #
      # @private
      class SingleFileWatcher < Coolio::StatWatcher
        class << self
          # Stores a reference back to handler so we can call its {Base#notify notify}
          # method with file event info
          #
          # @return [EventHandler::Base]
          #
          attr_accessor :handler
        end

        # @param [String] path
        #   single file to monitor
        #
        def initialize(path)
          super
          update_reference_times
        end

        # File's path as a Pathname
        #
        # @return [Pathname]
        #
        def pathname
          @pathname ||= Pathname(@path)
        end

        # Callback. Called on file change event. Delegates to
        # {Controller#update}, passing in path and event type
        #
        # @return [undefined]
        #
        def on_change
          self.class.handler.notify(path, type)
          update_reference_times unless type == :deleted
        end

        private

        # @todo improve ENOENT error handling
        def update_reference_times
          @reference_atime = pathname.atime
          @reference_mtime = pathname.mtime
          @reference_ctime = pathname.ctime
        rescue Errno::ENOENT
          retry
        end

        # Type of latest event.
        #
        # A single type is determined, even though more than one stat times may
        # have changed on the file. The type is the first to match in the
        # following hierarchy:
        #
        #     :deleted, :modified (mtime), :accessed (atime), :changed (ctime)
        #
        # @return [Symbol] type
        #   latest event's type
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
        @loop = Coolio::Loop.default
      end

      # Enters listening loop. Will block control flow until application is
      # explicitly stopped/killed.
      #
      # @return [undefined]
      #
      def listen(monitored_paths)
        @monitored_paths = monitored_paths
        attach
        @loop.run
      end

      # Rebuilds file bindings. Will detach all current bindings, and reattach
      # the `monitored_paths`
      #
      # @param [Array<Pathname>] monitored_paths
      #   list of paths the application is currently monitoring.
      #
      # @return [undefined]
      #
      def refresh(monitored_paths)
        @monitored_paths = monitored_paths
        detach
        attach
      end

      private

      # Binds all `monitored_paths` to the listening loop.
      #
      # @return [undefined]
      #
      def attach
        @monitored_paths.each {|path| SingleFileWatcher.new(path.to_s).attach(@loop) }
      end

      # Unbinds all paths currently attached to listening loop.
      #
      # @return [undefined]
      #
      def detach
        @loop.watchers.each {|watcher| watcher.detach }
      end
    end
  end
end
