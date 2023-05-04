# frozen_string_literal: true

require "hanami/router"

module Hanami
  class Router
    # @api public
    # @since 2.1.0
    class NotFoundError < Hanami::Router::Error
      def initialize(env)
        @env = env
        # TODO: generate helpful message
        super()
      end
    end

    # @api public
    # @since 2.1.0
    class NotAllowedError < Hanami::Router::Error
      def initialize(env, allowed_http_methods)
        @env = env
        @allowed_http_methods = allowed_http_methods

        # TODO: generate helpful message
        super()
      end
    end
  end
end
