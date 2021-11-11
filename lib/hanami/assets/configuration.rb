# frozen_string_literal: true

require "dry/configurable"

module Hanami
  module Assets
    # @since 2.0.0
    # @api public
    class Configuration
      include Dry::Configurable

      # Initialize the Configuration
      #
      # @yield [config] the configuration object
      #
      # @return [Configuration]
      #
      # @since 2.0.0
      # @api private
      def initialize(*)
        super
        yield self if block_given?
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        self.class.settings
      end

      private

      # @since 2.0.0
      # @api private
      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      # @since 2.0.0
      # @api private
      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
