module Watchr
  module EventHandler
    class Portable
      include Base

      attr_accessor :monitored_paths
      attr_accessor :reference_mtime

      def initialize
        @reference_mtime = Time.now
      end

      # Enters listening loop.
      #
      # Will block control flow until application is explicitly stopped/killed.
      #
      def listen(monitored_paths)
        @monitored_paths = monitored_paths
        loop { trigger; sleep(1) }
      end

      # See if an event occured, and if so notify observers.
      def trigger #:nodoc:
        path, type = detect_event
        notify(path, type) unless path.nil?
      end

      # Update list of monitored paths.
      def refresh(monitored_paths)
        @monitored_paths = monitored_paths
      end

      private

      # Verify mtimes of monitored files.
      #
      # If the latest mtime is more recent than the reference mtime, return
      # that file's path.
      #
      # ===== Returns
      # path and type of event if event occured, nil otherwise
      #
      def detect_event
        path = @monitored_paths.max {|a,b| a.mtime <=> b.mtime }

        if path.mtime > @reference_mtime
          @reference_mtime = path.mtime
          [path, :modified]
        else
          nil
        end
      end
    end
  end
end
