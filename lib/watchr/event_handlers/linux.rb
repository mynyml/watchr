require Watchr::ROOT + 'lib/c_ext/inotify'

module Watchr
  module EventHandler
    class Linux
      include Base

      #--
      # @dir_map is {wd => path}, where wd == watch descriptor, following
      # (ruby-)inotify vocabulary
      def initialize
        @inotify = Inotify.new
        @dir_map = {}
      end

      # callback
      #
      # @see Controller#run
      #
      def listen
        watch(monitored_paths)
        @inotify.each_event do |event|
          # if event.name.nil? then it's a dir event. ignore?
          path = @dir_map[event.wd] + (event.name || '')
          notify(path) if path.exist? && monitored_paths.include?(path)
        end
      end

      private

      def mask
        Inotify::MODIFY# |
        #Inotify::ATTRIB |
        #Inotify::CREATE |
        #Inotify::DELETE
      end

      def watch(paths)
        dirnames(paths).each do |path|
          wd = @inotify.add_watch(path.to_s, mask)
          @dir_map[wd] = path
        end
      end

      def dirnames(paths)
        paths.map {|path| path.directory? ? path : path.dirname }.uniq
      end
    end
  end
end
