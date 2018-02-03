require "concurrent"

module Hanami
  # @api private
  class Configuration
    # Middleware configuration
    class Middleware
      # @api private
      def initialize
        @middleware = Concurrent::Array.new
      end

      # Use a Rack middleware
      #
      # @param middleware [#call] a Rack middleware
      # @param args [Array<Object>] an optional set of options
      # @param blk [Proc] an optional block to pass to the middleware
      #
      # @since x.x.x
      #
      # @example
      #   # config/environment.rb
      #   # ...
      #   Hanami.configure do
      #     middleware.use MyRackMiddleware
      #   end
      def use(middleware, *args, &blk)
        @middleware.push([middleware, args, blk])
      end

      # @api private
      def each(&blk)
        @middleware.each(&blk)
      end
    end
  end
end
