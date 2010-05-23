module Watchr
  module EventHandler
    class FSEWatcher < ::FSEvent
      attr_reader :handler

      def initialize(handler)
        super()
        @handler = handler
        self.latency = 0.2
      end

      def on_change(dirs)
        handler.on_change(dirs)
      end
    end

    class FSE
      include Base

      attr_reader :watcher, :path_stats, :monitored_paths
      attr_accessor :controller

      def initialize
        @watcher = FSEWatcher.new(self)
        @path_stats = {}
      end

      def on_change(dirs)
        update_monitored_paths
        watch_monitored_paths
        dirs.each do |dir|
          #Watchr.debug "change in #{dir}"
          changed_pathname = Pathname(dir)
          monitored_paths.each do |pathname|
            if pathname.dirname.basename == changed_pathname.basename
              type = detect_change(pathname)
              if type
                #Watchr.debug type
                notify(pathname, type)
                update_path_stats(pathname) unless type == :deleted
              end
            end
          end
        end
      end

      def listen(monitored_paths)
        @monitored_paths = monitored_paths
        watch_monitored_paths
        @watcher.start
      end

      def refresh(monitored_paths)
        @monitored_paths = monitored_paths
        watch_monitored_paths
      end

      protected

      def watch_monitored_paths
        init_path_stats
        paths = monitored_paths.map {|p| p.dirname.to_s}.uniq
        @watcher.watch_directories(paths)
      end

      def init_path_stats
        now = Time.now
        monitored_paths.each do |pathname|
          unless path_stats[pathname]
            path_stats[pathname] = {:mtime => now, :atime => now, :ctime => now}
          end
        end
      end

      def detect_change(pathname)
        return :deleted   if !pathname.exist?
        return :modified  if  pathname.mtime > mtime(pathname)
        return :accessed  if  pathname.atime > atime(pathname)
        return :changed   if  pathname.ctime > ctime(pathname)
      end

      def update_monitored_paths
        @monitored_paths = controller.monitored_paths
      end

      def update_path_stats(pathname)
        path_stats[pathname][:mtime] = pathname.mtime
        path_stats[pathname][:atime] = pathname.atime
        path_stats[pathname][:ctime] = pathname.ctime
      end

      def mtime(pathname)
        path_stats[pathname][:mtime]
      end

      def atime(pathname)
        path_stats[pathname][:atime]
      end

      def ctime(pathname)
        path_stats[pathname][:ctime]
      end
    end
  end
end

