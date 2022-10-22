# frozen_string_literal: true

require "dry/configurable"

module Hanami
  # @api private
  module Assets
    # App config for assets.
    #
    # This is NOT RELEASED as of 2.0.0.
    #
    # @api private
    class AppConfig
      include Dry::Configurable

      attr_reader :base_config
      protected :base_config

      setting :server_url, default: "http://localhost:8080"

      def initialize(*)
        super

        @base_config = Assets::Config.new
      end

      def initialize_copy(source)
        super
        @base_config = source.base_config.dup
      end

      def finalize!
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @api private
      def settings
        base_config.settings + self.class.settings
      end

      private

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_config.respond_to?(name)
          base_config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_config.respond_to?(name) || super
      end
    end
  end
end
