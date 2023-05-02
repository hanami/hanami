# frozen_string_literal: true

require "hanami/router"

module Hanami
  class Router
    class NotFoundError < Hanami::Router::Error
      def initialize(env)
        @env = env
        # TODO: generate helpful message
        super()
      end
    end

    class MethodNotAllowedError < Hanami::Router::Error
    end
  end
end
