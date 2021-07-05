# frozen_string_literal: true

module Hanami
  class Application
    # Hanami application router
    # @since 2.0.0
    class RoutesHelper < ::Hanami::Router
      # @since 2.0.0
      # @api private
      def initialize(router)
        @router = router
      end

      def path(...)
        @router.path(...)
      end

      def url(...)
        @router.url(...)
      end
    end
  end
end
