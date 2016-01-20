module Hanami
  module Config
    # Collects all the settings for a given framework configuration and then
    # forwards them when the application is loaded.
    #
    # @since 0.2.0
    # @api private
    class FrameworkConfiguration < BasicObject
      # @since 0.2.0
      # @api private
      def initialize(&blk)
        @blocks   = [blk || ::Proc.new { }]
        @settings = []
      end

      # @since 0.2.0
      # @api private
      def __apply(configuration)
        @blocks.compact.each do |blk|
          configuration.instance_eval(&blk)
        end

        @settings.each do |(m, args, blk)|
          configuration.public_send(m, *args, &blk)
        end
      end

      # @since 0.6.0
      # @api private
      def __add(&blk)
        @blocks << blk
        self
      end

      # @since 0.2.0
      # @api private
      def method_missing(m, *args, &blk)
        @settings.push([m, args, blk])
      end
    end
  end
end
