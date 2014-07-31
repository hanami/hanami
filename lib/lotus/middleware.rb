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
      @stack = []

      if configuration.assets.enabled?
        configuration.assets.paths.each do |path|
          use Rack::Static, {
            urls: path.entries,
            root: path
          }
        end
      end
    end

    # Load the middleware stack
    #
    # @param application [Lotus::Application] the application loading the middleware
    #
    # @return [Lotus::Middleware] the loaded middleware stack
    #
    # @since x.x.x
    # @api private
    #
    # @see http://rdoc.info/gems/rack/Rack/Builder
    def load!(application, namespace)
      @namespace = namespace
      @builder = ::Rack::Builder.new
      @stack.each { |m, args, block| @builder.use load_middleware(m), *args, &block }
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
    # @since x.x.x
    def use(middleware, *args, &blk)
      @stack << [middleware, args, blk]
    end

    # @api private
    # @since x.x.x
    def load_middleware(middleware)
      case middleware
      when String
        @namespace.const_get(middleware)
      else
        middleware
      end
    end
  end
end
