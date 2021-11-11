# frozen_string_literal: true

require "hanami/assets/configuration"
require "dry/configurable"

module Hanami
  module Assets
    class ApplicationConfiguration
      include Dry::Configurable

      setting :server_url, default: "http://localhost:8080"

      def initialize(*)
        super

        @base_configuration = Assets::Configuration.new
      end

      def finalize!
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        base_configuration.settings + self.class.settings
      end

      private

      attr_reader :base_configuration

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_configuration.respond_to?(name)
          base_configuration.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_configuration.respond_to?(name) || super
      end
    end
  end
end
