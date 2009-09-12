module Watchr
  module EventHandler
    class Portable
      include Base

      attr_accessor :monitored_paths
      attr_accessor :reference_mtime

      def initialize
        @reference_mtime = Time.now
      end

      def listen(monitored_paths)
        @monitored_paths = monitored_paths
        loop { trigger; sleep(1) }
      end

      def trigger
        path, type = detect_event
        notify(path, type) unless path.nil?
      end

      def refresh(monitored_paths)
        @monitored_paths = monitored_paths
      end

      private

      # ===== Returns
      # path<Pathname>::
      #   path for which the event occured, or nil if no event occured
      #
      def detect_event
        path = @monitored_paths.max {|a,b| a.mtime <=> b.mtime }

        if path.mtime > @reference_mtime
          @reference_mtime = path.mtime
          [path, :changed]
        else
          nil
        end
      end
    end
  end
end
