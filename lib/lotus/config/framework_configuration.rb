module Lotus
  module Config
    # Collects all the settings for a given framework configuration and then
    # forwards them when the application is loaded.
    #
    # @since x.x.x
    # @api private
    class FrameworkConfiguration < BasicObject
      # @since x.x.x
      # @api private
      def initialize
        @settings = []
      end

      # @since x.x.x
      # @api private
      def __apply(configuration)
        @settings.each do |(m, args, blk)|
          configuration.public_send(m, *args, &blk)
        end
      end

      # @since x.x.x
      # @api private
      def method_missing(m, *args, &blk)
        @settings.push([m, args, blk])
      end
    end
  end
end
