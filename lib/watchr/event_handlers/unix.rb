require 'eventmachine'

# Event handler keeps segfaulting when running the specs so this handler
# isn't yet usable.
#
#   "/usr/lib/ruby/gems/1.8/gems/eventmachine-0.12.8/lib/eventmachine.rb:245: [BUG] Segmentation fault"
#
# See also eventmachine/tests/test_basic.rb:~129 (as of commit 60f9cb28490af0073b862f8e6d0d9f0d93382843)
# for an explanation of the bug.
#
module Watchr
  module EventHandler

    class Unix
      include Base

      module Callbacks
        def initialize(handler)
          @handler = handler
        end

        def file_modified
          @handler.notify(path, :modified)
        end

        def file_moved()    end
        def file_deleted()  end
        def unbind()        end
      end

      def listen
        EM.run {
          monitored_paths.each {|p| EM.watch_file(p.to_s, Callbacks, self) }
        }
      end
    end
  end
end
