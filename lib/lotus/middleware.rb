module Lotus
  # Rack middleware stack for an application
  #
  # @since 0.1.0
  # @api private
  class Middleware
    # Instantiate a middleware stack
    #
    # @param configuration [Lotus::Configuration] the application's configuration
    #
    # @return [Lotus::Middleware] the new stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see Lotus::Configuration
    def initialize(configuration)
      # Initialize the default Middleware stack
      @stack = []

      if configuration.assets
        use Rack::Static, {
          urls: configuration.assets.entries,
          root: configuration.assets
        }
      end
    end

    # Load the middleware stack
    #
    # @param application [Lotus::Application] the application loading the middleware
    #
    # @return [Lotus::Middleware] the loaded middleware stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see http://rdoc.info/gems/rack/Rack/Builder
    def load!(application)
      @builder = ::Rack::Builder.new
      @stack.each { |m, args, block| @builder.use m, *args, &block }
      @builder.run application.routes

      self
    end

    # Process a request.
    # This method makes the middleware stack compatible with the Rack protocol.
    #
    # @param env [Hash] a Rack env
    #
    # @return [Array] a serialized Rack response
    #
    # @since 0.1.0
    # @api private
    def call(env)
      @builder.call(env)
    end

    # Add a middleware to the stack.
    #
    # @param middleware [Object] a Rack middleware
    # @param *args [Array] optional arguments to pass to the Rack middleware
    # @param &blk [Proc] an optional block to pass to the Rack middleware
    #
    # @return [Array] the middleware that was added
    #
    # @since 0.1.0
    def use(middleware, *args, &blk)
      @stack << [middleware, args, blk]
    end
  end
end
