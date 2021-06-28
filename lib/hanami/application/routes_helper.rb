# frozen_string_literal: true

module Hanami
  class Application
    # Hanami application routes helpers
    #
    # An instance of this class gets registered in the container
    # (`routes_helper` key) once the Hanami application is booted. You can use
    # it to get the route helpers for your application.
    #
    # @example
    #   MyApp::Aplication["routes_helper"].path(:root) # => "/"
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
      def path(*args, **kwargs, &block)
        @router.path(*args, **kwargs, &block)
      end

      # @see Hanami::Router::UrlHelpers#url
      def url(*args, **kwargs, &block)
        @router.url(*args, **kwargs, &block)
      end
    end
  end
end
