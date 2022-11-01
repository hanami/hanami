# frozen_string_literal: true

require "dry/configurable"
require "hanami/logger"

module Hanami
  class Config
    # Hanami logger config
    #
    # @api public
    # @since 2.0.0
    class Logger
      include Dry::Configurable

      # @return [Hanami::SliceName]
      #
      # @api private
      # @since 2.0.o
      attr_reader :app_name

      # @!attribute [rw] level
      #   Sets or returns the logger level.
      #
      #   Defaults to `:info` for the production environment and `:debug` for all others.
      #
      #   @return [Symbol]
      #
      #   @api public
      #   @since 2.0.0
      setting :level

      # @!attribute [rw] stream
      #   Sets or returns the logger's stream.
      #
      #   This can be a file path or an `IO`-like object for the logger to write to.
      #
      #   Defaults to `"log/test.log"` for the test environment and `$stdout` for all others.
      #
      #   @return [String, #write]
      #
      #   @api public
      #   @since 2.0.0
      setting :stream

      # @!attribute [rw] formatter
      #   Sets or returns the logger's formatter.
      #
      #   This may be a name that matches a formatter registered with `Hanami::Logger`, which
      #   includes `:default` and `:json`.
      #
      #   This may also be an instance of Ruby's built-in `::Logger::Formatter` or any compatible
      #   object.
      #
      #   Defaults to `:json` for the production environment, and `nil` for all others. A `nil`
      #   value will result in a plain `::Logger::Formatter` instance.
      #
      #   @return [Symbol, ::Logger::Formatter]
      #
      #   @api public
      #   @since 2.0.0
      setting :formatter

      # @!attribute [rw] colors
      #   Sets or returns whether log lines should be colorized.
      #
      #   Defaults to `false`.
      #
      #   @return [Boolean]
      #
      #   @api public
      #   @since 2.0.0
      setting :colors, default: false

      # @!attribute [rw] filters
      #   Sets or returns an array of attribute names to filter from logs.
      #
      #   Defaults to `["_csrf", "password", "password_confirmation"]`. If you want to preserve
      #   these defaults, append to this array rather than reassigning it.
      #
      #   @return [Array<String>]
      #
      #   @api public
      #   @since 2.0.0
      setting :filters, default: %w[_csrf password password_confirmation].freeze

      # @!attribute [rw] logger_class
      #   Sets or returns the class to use for the logger.
      #
      #   This should be compatible with the arguments passed to the logger class' `.new` method in
      #   {#instance}.
      #
      #   Defaults to `Hanami::Logger`.
      #
      #   @api public
      #   @since 2.0.0
      setting :logger_class, default: Hanami::Logger

      # @!attribute [rw] options
      #   Sets or returns an array of positional arguments to pass to the {logger_class} when
      #   initializing the logger.
      #
      #   Defaults to `[]`
      #
      #   @return [Array<Object>]
      #
      #   @api public
      #   @since 2.0.0
      setting :options, default: [], constructor: ->(value) { Array(value).flatten }

      # Returns a new `Logger` config.
      #
      # You should not need to initialize this directly, instead use {Hanami::Config#logger}.
      #
      # @param env [Symbol] the Hanami env
      # @param app_name [Hanami::SliceName]
      #
      # @api private
      def initialize(env:, app_name:)
        @app_name = app_name

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
      end

      # Returns a new instance of the logger.
      #
      # @return [logger_class]
      #
      # @api public
      # @since 2.0.0
      def instance
        logger_class.new(
          app_name.name,
          *options,
          stream: stream,
          level: level,
          formatter: formatter,
          filter: filters,
          colorizer: colors
        )
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
