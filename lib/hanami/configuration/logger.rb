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

      setting :formatter

      setting :colors

      setting :filters, default: %w[_csrf password password_confirmation].freeze

      setting :options, default: [], constructor: ->(value) { Array(value).flatten }, cloneable: true

      setting :logger_class, default: Hanami::Logger

      def initialize(env:, application_name:)
        @env = env
        @application_name = application_name

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

        config.formatter = case env
                           when :production
                             :json
                           end

        config.colors = case env
                        when :production, :test
                          false
                        end
      end

      def finalize!
        config.application_name = @application_name.call
      end

      def instance
        logger_class.new(application_name, *options, stream: stream, level: level, formatter: formatter, filter: filters, colorizer: colors)
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
