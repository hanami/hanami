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
    #   MyApp::Application["routes_helper"].path(:root) # => "/"
    #
    # @see Hanami::Router::UrlHelpers
    # @since 2.0.0
    class RoutesHelper
      # @since 2.0.0
      # @api private
      def initialize(router_proc)
        # Expect the router wrapped in a proc so we can defer loading the router until it
        # is needed. This also means we can avoid loading it entirely in where it is not
        # required at all.
        #
        # This is an issue because the application's RoutesHelper instance is always
        # initialized and registered with the application via a provider. This will be
        # fixed in the upcoming application/slice unification, where the provider will
        # only be registered if routes actually exist.
        @router_proc = router_proc
      end

      # @see Hanami::Router::UrlHelpers#path
      def path(*args, **kwargs, &block)
        router.path(*args, **kwargs, &block)
      end

      # @see Hanami::Router::UrlHelpers#url
      def url(*args, **kwargs, &block)
        router.url(*args, **kwargs, &block)
      end

      private

      def router
        @router ||= @router_proc.call
      end
    end
  end
end
