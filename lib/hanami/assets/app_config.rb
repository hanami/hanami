# frozen_string_literal: true

require "dry/configurable"
require_relative "config"

module Hanami
  module Assets
    # @since 2.0.0
    # @api public
    class AppConfig
      include Dry::Configurable

      # @since 2.0.0
      # @api private
      attr_reader :base_config
      protected :base_config

      setting :server_url, default: "http://localhost:8080"

      # @since 2.0.0
      # @api private
      def initialize(*)
        super

        @base_config = Config.new
      end

      def initialize_copy(source)
        super
        @base_config = source.base_config.dup
      end

      # @since 2.0.0
      # @api private
      def finalize!
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        base_config.settings + self.class.settings
      end

      private

      # @since 2.0.0
      # @api private
      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_config.respond_to?(name)
          base_config.public_send(name, *args, &block)
        else
          super
        end
      end

      # @since 2.0.0
      # @api private
      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_config.respond_to?(name) || super
      end
    end
  end
end
