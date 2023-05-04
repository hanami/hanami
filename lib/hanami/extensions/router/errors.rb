# frozen_string_literal: true

require "hanami/router"

module Hanami
  class Router
    # Error raised when a request is made for a missing route.
    #
    # Raised only when using hanami-router as part of a full Hanami app. When using hanami-router
    # standalone, the behavior for such requests is to return a "Not Found" response.
    #
    # @api public
    # @since 2.1.0
    class NotFoundError < Hanami::Router::Error
      # @return [Hash] the Rack environment for the request
      #
      # @api public
      # @since 2.1.0
      attr_reader :env

      def initialize(env)
        @env = env

        message = "No route found for #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
        super(message)
      end
    end

    # Error raised when a request is made for a route using a HTTP method not allowed on the route.
    #
    # Raised only when using hanami-router as part of a full Hanami app. When using hanami-router
    # standalone, the behavior for such requests is to return a "Method Not Allowed" response.
    #
    # @api public
    # @since 2.1.0
    class NotAllowedError < Hanami::Router::Error
      # @return [Hash] the Rack environment for the request
      #
      # @api public
      # @since 2.1.0
      attr_reader :env

      # @return [Array<String>] the allowed methods for the route
      #
      # @api public
      # @since 2.1.0
      attr_reader :allowed_methods

      def initialize(env, allowed_methods)
        @env = env
        @allowed_methods = allowed_methods

        message = "Only #{allowed_methods.join(', ')} requests are allowed at #{env["PATH_INFO"]}"
        super(message)
      end
    end
  end
end
