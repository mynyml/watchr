require 'observer'

module Watchr
  module EventHandler
    class AbstractMethod < Exception #:nodoc:
    end

    # Base functionality mixin meant to be included in specific event handlers.
    module Base
      include Observable

      # Notify that a file was modified.
      #
      # ===== Parameters
      # path<Pathname, String>:: full path or path relative to current working directory
      # event_type<Symbol>:: event type.
      #--
      # #changed and #notify_observers are Observable methods
      def notify(path, event_type = nil)
        changed(true)
        notify_observers(path, event_type)
      end

      # Begin watching given paths and enter listening loop. Called by the controller.
      #
      # Abstract method
      #
      # ===== Parameters
      # monitored_paths<Array(Pathname)>:: list of paths the application is currently monitoring.
      #
      def listen(monitored_paths)
        raise AbstractMethod
      end

      # Called by the controller when the list of paths monitored by wantchr
      # has changed. It should refresh the list of paths being watched.
      #
      # Abstract method
      #
      # ===== Parameters
      # monitored_paths<Array(Pathname)>:: list of paths the application is currently monitoring.
      #
      def refresh(monitored_paths)
        raise AbstractMethod
      end
    end
  end
end
