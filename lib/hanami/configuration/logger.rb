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

      # Holds a user-supplied pre-initialized logger instance. This should be used in
      # preference to the `logger_class` and `options`
      setting :instance

      setting :logger_class, Hanami::Logger

      setting :options, {level: :debug}

      # Currently used for logging of Rack requests only.
      #
      # TODO: incorporate this into the standard logging some way or another
      setting :filter_params, %w[_csrf password password_confirmation].freeze

      private

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
