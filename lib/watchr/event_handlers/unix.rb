require 'eventmachine'

module Watchr
  class UnixEventHandler < AbstractEventHandler

    module EmHandler
      def file_modified
      end
  
      def file_moved
      end
  
      def file_deleted
      end
  
      def unbind
      end
    end

    def listen(paths)
      # notify(path)
    end
  end
end
