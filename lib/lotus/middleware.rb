module Lotus
  # Rack middleware stack for an application
  #
  # @since 0.1.0
  # @api private
  class Middleware
    # Instantiate a middleware stack
    #
    # @param application [Lotus::Application] the application
    #
    # @return [Lotus::Middleware] the new stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see Lotus::Configuration
    # @see http://rdoc.info/gems/rack/Rack/Builder
    def initialize(application)
      configuration = application.configuration
      routes        = application.routes

      @builder = ::Rack::Builder.new
      @builder.use Rack::Static,
        urls: configuration.assets.entries,
        root: configuration.assets
      @builder.run routes
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
  end
end
