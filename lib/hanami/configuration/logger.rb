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

      setting :application_name

      setting :level

      setting :stream

      setting :logger_class, default: Hanami::Logger

      setting :options, default: {level: :debug}

      # Currently used for logging of Rack requests only.
      #
      # TODO: incorporate this into the standard logging some way or another
      setting :filter_params, default: %w[_csrf password password_confirmation].freeze

      def initialize(env:, application_name:)
        @env = env
        config.application_name = application_name

        config.level = case env
                       when :production
                         :info
                       else
                         :debug
                       end

        config.stream = case env
                        when :test
                          File.join("log", "#{env}.log")
                        else
                          $stdout
                        end
      end

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
