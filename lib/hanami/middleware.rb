require 'rack/builder'
require 'hanami/utils/class'

module Hanami
  # Rack middleware stack for an application
  #
  # @since 0.1.0
  # @api private
  class Middleware
    # Instantiate a middleware stack
    #
    # @param configuration [Hanami::ApplicationConfiguration] the application's configuration
    #
    # @return [Hanami::Middleware] the new stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::ApplicationConfiguration
    def initialize(configuration)
      @stack         = []
      @configuration = configuration
      @builder       = Rack::Builder.new
    end

    # Load the middleware stack
    #
    # @return [Hanami::Middleware] the loaded middleware stack
    #
    # @since 0.2.0
    # @api private
    #
    # @see http://rdoc.info/gems/rack/Rack/Builder
    def load!
      load_default_stack
      stack.each { |m, args, block| builder.use(load_middleware(m), *args, &block) }
      builder.run routes

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
      builder.call(env)
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
    # @see Hanami::Middleware#prepend
    #
    # @example
    #   # apps/web/application.rb
    #   module Web
    #     class Application < Hanami::Application
    #       configure do
    #         # ...
    #         use MyRackMiddleware, foo: 'bar'
    #       end
    #     end
    #   end
    def use(middleware, *args, &blk)
      stack.push [middleware, args, blk]
      stack.uniq!
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
    # @see Hanami::Middleware#use
    #
    # @example
    #   # apps/web/application.rb
    #   module Web
    #     class Application < Hanami::Application
    #       configure do
    #         # ...
    #         prepend MyRackMiddleware, foo: 'bar'
    #       end
    #     end
    #   end
    def prepend(middleware, *args, &blk)
      stack.unshift [middleware, args, blk]
      stack.uniq!
    end

    private

    # @api private
    # @since 0.9.0
    attr_reader :stack

    # @api private
    # @since 0.9.0
    attr_reader :builder

    # @api private
    # @since 0.9.0
    attr_reader :configuration

    # @api private
    # @since 0.2.0
    def load_middleware(middleware)
      case middleware
      when String
        Utils::Class.load!(middleware)
      else
        middleware
      end
    end

    # @api private
    # @since 0.9.0
    def routes
      Components["#{configuration.app_name}.routes"]
    end

    # @api private
    # @since 0.2.0
    def load_default_stack
      @default_stack_loaded ||= begin
        _load_session_middleware
        _load_default_welcome_page

        true
      end
    end

    # Default welcome page
    #
    # @api private
    # @since 0.2.0
    def _load_default_welcome_page
      unless Hanami.env?(:test) || routes.defined?
        require 'hanami/welcome'
        use Hanami::Welcome
      end
    end

    # Add session middleware
    #
    # @api private
    # @since 0.2.0
    def _load_session_middleware
      if configuration.sessions.enabled?
        prepend(*configuration.sessions.middleware)
      end
    end
  end
end
