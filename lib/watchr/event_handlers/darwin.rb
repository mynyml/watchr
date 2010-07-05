module Watchr
  module EventHandler
    class Darwin < FSEvent
      include Base

      def initialize
        super
        self.latency = 0.2
      end

      def listen(monitored_paths)
        register_paths(monitored_paths)
        start
      end

      def refresh(monitored_paths)
        register_paths(monitored_paths)
        restart
      end

      private
        def on_change(dirs)
          dirs.each do |dir|
            path, type = detect_change(dir)
            notify(path, type) unless path.nil?
          end
        end

        def detect_change(dir)
          paths = monitored_paths_for(dir)
          type  = nil
          path  = paths.find {|path| type = event_type(path) }

          if type == :accessed || type.nil?
            Watchr.debug "NO CHANGE DETECTED"
            Watchr.debug "type:  #{type.inspect}"
            Watchr.debug "dir:   #{dir.inspect}"
            Watchr.debug "path:  #{path.inspect}"
            Watchr.debug "refs:  #{@reference_times[path].inspect }"
            Watchr.debug "/ NO CHANGE DETECTED"
          end

          update_reference_times
          [path, type]
        end

        def event_type(path)
          return :deleted   if !path.exist?
          return :modified  if  path.mtime > @reference_times[path][:mtime]
          return :accessed  if  path.atime > @reference_times[path][:atime]
          return :changed   if  path.ctime > @reference_times[path][:ctime]
          nil
        end

        def monitored_paths_for(dir)
          dir = Pathname(dir).expand_path
          @paths.select {|path| path.dirname.expand_path == dir }
        end

        def register_paths(paths)
          @paths = paths
          watch_directories(dirs_for(@paths))
          update_reference_times
        end

        def dirs_for(paths)
          paths.map {|path| path.dirname.to_s }.uniq
        end

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

