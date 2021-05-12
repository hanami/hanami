# frozen_string_literal: true

require "dry/configurable"
require "hanami/logger"

module Hanami
  class Configuration
    # Hanami logger configuration
    #
    # @since 2.0.0
    class Logger
      include Dry::Configurable

      protected :config

      def initialize(instance = nil)
        self.instance = instance
      end

      setting :instance

      def instance
        config.instance || build_logger
      end

      setting :logger_class, Hanami::Logger

      setting :options, {level: :debug}

      setting :filter_params, %w[_csrf password password_confirmation].freeze

      private

      def build_logger
        logger_class.new(**options)
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
