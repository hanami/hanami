# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami router configuration
    #
    # @since 2.0.0
    class Router
      attr_writer :routes
      attr_reader :routes

      attr_writer :resolver

      def initialize(base_url, routes: DEFAULT_ROUTES)
        @base_url = base_url
        @routes = routes
      end

      def resolver
        @resolver ||= begin
                        require_relative "../application/routing/resolver"
                        Application::Routing::Resolver
                      end
      end

      def options
        { base_url: @base_url }
      end

      DEFAULT_ROUTES = File.join("config", "routes")
      private_constant :DEFAULT_ROUTES
    end
  end
end
