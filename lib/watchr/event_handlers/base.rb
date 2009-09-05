require 'observer'

module Watchr
  module EventHandler
    class AbstractMethod < Exception; end

    module Base
      include Observable

      # time the listener is expected to take before it notices a new event
      # nil if almost immediate
      # typically set if listener sleeps in between event checks
      attr_reader :delay

      # notify that a file was modified
      # note: must notify observer with full path or path relative to Dir.pwd
      def notify(path, event = nil)
        changed(true)                 #from Observable
        notify_observers(path, event) #calls #update on each observer
      end

      # abstract method
      def listen(monitored_paths)
        raise AbstractMethod
      end

      def terminate!
        @terminate = true
      end

      def terminate?
        !!@terminate
      end
    end
  end
end
