# frozen_string_literal: true

require "dry/configurable"
require_relative "../application/routing/resolver"

module Hanami
  class Configuration
    # Hanami router configuration
    #
    # @since 2.0.0
    # @api private
    class Router
      include Dry::Configurable

      # Base configuration is provided so router config can include the `base_url`
      attr_reader :base_configuration
      private :base_configuration

      # @api private
      # @since 2.0.0
      def initialize(base_configuration)
        @base_configuration = base_configuration
      end

      setting :routes_path, default: File.join("config", "routes")

      setting :routes_class_name, default: "Routes"

      setting :resolver, default: Application::Routing::Resolver

      # @api private
      # @since 2.0.0
      def options
        {base_url: base_configuration.base_url}
      end

      private

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
