# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami router configuration
    #
    # @since 2.0.0
    # @api private
    class Router
      # @api private
      # @since 2.0.0
      attr_writer :resolver

      # @api private
      # @since 2.0.0
      def initialize(base_url)
        @base_url = base_url
      end

      # @api private
      # @since 2.0.0
      def resolver
        @resolver ||= begin
                        require_relative "../application/routing/resolver"
                        Application::Routing::Resolver
                      end
      end

      # @api private
      # @since 2.0.0
      def options
        { base_url: @base_url }
      end
    end
  end
end
