require 'observer'

module Watchr
  module EventHandler

    # @private
    class AbstractMethod < Exception; end

    # Base functionality mixin, meant to be included in specific event handlers.
    #
    # @abstract
    module Base
      include Observable

      # Notify that a file was modified.
      #
      # @param [Pathname, String] path
      #   full path or path relative to current working directory
      #
      # @param [Symbol] event
      #   event type.
      #
      # @return [undefined]
      #
      def notify(path, event_type = nil)
        changed(true)
        notify_observers(path, event_type)
      end

      # Begin watching given paths and enter listening loop. Called by the
      # controller.
      #
      # @param [Array<Pathname>] monitored_paths
      #   list of paths the application is currently monitoring.
      #
      # @return [undefined]
      #
      # @abstract
      def listen(monitored_paths)
        raise AbstractMethod
      end

      # Called by the controller when the list of paths monitored by wantchr
      # has changed. It should refresh the list of paths being watched.
      #
      # @param [Array<Pathname>] monitored_paths
      #   list of paths the application is currently monitoring.
      #
      # @return [undefined]
      #
      # @abstract
      def refresh(monitored_paths)
        raise AbstractMethod
      end
    end
  end
end
