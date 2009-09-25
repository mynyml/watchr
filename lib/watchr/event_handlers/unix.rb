require 'eventmachine'

module Watchr
  module EventHandler
    class Unix
      include Base

      # Used by EventMachine. Wraps a monitored path, and EM will call its
      # callbacks on file events.
      class SingleFileWatcher < EM::FileWatch #:nodoc:

        # ===== Parameters
        # handler<EventHandler::Base>:: a handler object to notify
        #
        def initialize(handler)
          @handler = handler
        end

        # Callback. Called on file change event
        # Delegates to Controller#update, passing in path and event type
        def file_modified
          @handler.notify(path, :changed)
        end
      end

      def initialize #:nodoc:
        @watchers = []
      end

      # Enters listening loop.
      #
      # Will block control flow until application is explicitly stopped/killed.
      #
      def listen(monitored_paths)
        @monitored_paths = monitored_paths
        EM.run { attach }
      end

      # Rebuilds file bindings.
      #
      # will detach all current bindings, and reattach the <tt>monitored_paths</tt>
      #
      def refresh(monitored_paths)
        @monitored_paths = monitored_paths
        EM.next_tick { detach; attach }
      end

      private

      # Binds all <tt>monitored_paths</tt> to the listening loop.
      def attach
        @monitored_paths.each {|p| @watchers << EM.watch_file(p.to_s, SingleFileWatcher, self) }
      end

      # Unbinds all paths currently attached to listening loop.
      def detach
        @watchers.each {|w| w.stop_watching }
        @watchers.clear
      end
    end
  end
end
