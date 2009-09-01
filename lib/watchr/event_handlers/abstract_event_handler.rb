require 'observer'

module Watchr
  class AbstractMethod < Exception; end

  class AbstractEventHandler
    include Observable

    # time the listener is expected to take before it notices a new event
    # nil if almost immediate
    # typically set if listener sleeps in between event checks
    attr_reader :delay

    # notify that a file was modified
    # note: must notify observer with full path or path relative to Dir.pwd
    def notify(path, event = nil)
      changed(true) #from Observable
      notify_observers(path, event)
    end

    # abstract method
    def listen(paths)
      raise AbstractMethod
    end
  end
end
