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
      @configuration = configuration
    end

    # Load the middleware stack
    #
    # @param application [Lotus::Application] the application loading the middleware
    #
    # @return [Lotus::Middleware] the loaded middleware stack
    #
    # @since 0.2.0
    # @api private
    #
    # @see http://rdoc.info/gems/rack/Rack/Builder
    def load!(application, namespace)
      @namespace = namespace
      @builder = ::Rack::Builder.new
      load_default_stack(application)
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

    # Append a middleware to the stack.
    #
    # @param middleware [Object] a Rack middleware
    # @param args [Array] optional arguments to pass to the Rack middleware
    # @param blk [Proc] an optional block to pass to the Rack middleware
    #
    # @return [Array] the middleware that was added
    #
    # @since 0.2.0
    #
    # @see Lotus::Middleware#prepend
    def use(middleware, *args, &blk)
      @stack.push [middleware, args, blk]
    end

    # Prepend a middleware to the stack.
    #
    # @param middleware [Object] a Rack middleware
    # @param args [Array] optional arguments to pass to the Rack middleware
    # @param blk [Proc] an optional block to pass to the Rack middleware
    #
    # @return [Array] the middleware that was added
    #
    # @since 0.6.0
    #
    # @see Lotus::Middleware#use
    def prepend(middleware, *args, &blk)
      @stack.unshift [middleware, args, blk]
    end

    # @api private
    # @since 0.2.0
    def load_middleware(middleware)
      case middleware
      when String
        @namespace.const_get(middleware)
      else
        middleware
      end
    end

    # @api private
    # @since 0.2.0
    def load_default_stack(application)
      @default_stack_loaded ||= begin
        _load_assets_middleware
        _load_session_middleware
        _load_default_welcome_page_for(application)
        use Rack::MethodOverride

        true
      end
    end

    # Default welcome page
    #
    # @api private
    # @since 0.2.0
    def _load_default_welcome_page_for(application)
      unless Lotus.env?(:test) || application.routes.defined?
        require 'lotus/welcome'
        use Lotus::Welcome
      end
    end

    # Add session middleware
    #
    # @api private
    # @since 0.2.0
    def _load_session_middleware
      if @configuration.sessions.enabled?
        prepend(*@configuration.sessions.middleware)
      end
    end

    # Use static assets middleware
    #
    # @api private
    # @since 0.6.0
    def _load_assets_middleware
      env = Lotus.environment

      if !env.container? && env.serve_static_assets?
        require 'lotus/static'
        use Lotus::Static
      end
    end
  end
end
