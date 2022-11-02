# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Config
    # Hanami router config
    #
    # @since 2.0.0
    # @api private
    class Router
      include Dry::Configurable

      # Base config is provided so router config can include the `base_url`
      attr_reader :base_config
      private :base_config

      # @api private
      # @since 2.0.0
      def initialize(base_config)
        @base_config = base_config
      end

      setting :resolver, default: Slice::Routing::Resolver

      # @api private
      # @since 2.0.0
      def options
        {base_url: base_config.base_url}
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
