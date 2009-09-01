require Watchr::ROOT + 'ext/inotify'

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
      # @arg paths <String,...> Monitored paths. Assume all exist.
      # @see Controller#run
      #
      def listen(paths)
        watch(paths)
        @inotify.each_event do |event|
          # if event.name.nil? then it's a dir event. ignore?
          path = @dir_map[event.wd] + (event.name || '')
          notify(path.to_s)
        end
      end

      private

      def mask
        Inotify::ATTRIB #|
        #Inotify::MODIFY |
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
        paths.map do |path|
          path = Pathname(path).expand_path
          path.directory? ? path : path.dirname
        end.uniq
      end
    end
  end
end
