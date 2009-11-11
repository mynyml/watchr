module Watchr
  module EventHandler
    class Portable
      include Base

      def initialize
        @reference_mtime = @reference_atime = @reference_ctime = Time.now
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
      #--
      # OPTIMIZE, REFACTOR
      # TODO fix/figure out ENOENT error
      def detect_event
        @monitored_paths.each do |path|
          return [path, :deleted] unless path.exist?
        end

        mtime_path = @monitored_paths.max {|a,b| a.mtime <=> b.mtime }
        atime_path = @monitored_paths.max {|a,b| a.atime <=> b.atime }
        ctime_path = @monitored_paths.max {|a,b| a.ctime <=> b.ctime }

        if    mtime_path.mtime > @reference_mtime then @reference_mtime = mtime_path.mtime; [mtime_path, :modified]
        elsif atime_path.atime > @reference_atime then @reference_atime = atime_path.atime; [atime_path, :accessed]
        elsif ctime_path.ctime > @reference_ctime then @reference_ctime = ctime_path.ctime; [ctime_path, :changed ]
        else; nil; end
      rescue Errno::ENOENT
        retry
      end
    end
  end
end
