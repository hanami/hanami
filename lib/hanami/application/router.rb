# frozen_string_literal: true

require "hanami/api/router"
require "rack"

module Hanami
  class Application
    # Hanami application router
    # @since 2.0.0
    class Router < Hanami::API::Router
      def slice(name, at:, &blk)
        path = prefixed_path(at)
        @resolver.register_slice(path, name)

        scope(path, &blk)
      end
    end
  end
end
