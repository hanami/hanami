# frozen_string_literal: true

module Hanami
  class Slice
    # Hanami app routes helpers
    #
    # An instance of this class will be registered with slice (at the "routes" key). You
    # can use it to access the route helpers for your app.
    #
    # @example
    #   MyApp::App["routes"].path(:root) # => "/"
    #
    # @see Hanami::Router::UrlHelpers
    # @since 2.0.0
    class RoutesHelper
      # @since 2.0.0
      # @api private
      def initialize(router)
        @router = router
      end

      # @see Hanami::Router::UrlHelpers#path
      def path(...)
        router.path(...)
      end

      # @see Hanami::Router::UrlHelpers#url
      def url(...)
        router.url(...)
      end

      private

      attr_reader :router
    end
  end
end
