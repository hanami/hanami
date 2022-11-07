# frozen_string_literal: true

require "dry/configurable"
require "dry/logger"

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
      #   This may be a name that matches a formatter registered with `Dry::Logger`, which includes
      #   `:string`, `:rack` and `:json`.
      #
      #   This may also be an instance of Ruby's built-in `::Logger::Formatter` or any compatible
      #   object.
      #
      #   Defaults to `:json` for the production environment, and `:rack` for all others.
      #
      #   @return [Symbol, ::Logger::Formatter]
      #
      #   @api public
      #   @since 2.0.0
      setting :formatter

      # @!attribute [rw] template
      #   Sets or returns log entry string template
      #
      #   Defaults to `false`.
      #
      #   @return [Boolean]
      #
      #   @api public
      #   @since 2.0.0
      setting :template, default: "[%<progname>s] [%<severity>s] [%<time>s] %<message>s"

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

      # @!attribute [rw] logger_constructor
      #   Sets or returns the constructor proc to use for the logger instantiation.
      #
      #   Defaults to `Dry.method(:Logger)`.
      #
      #   @api public
      #   @since 2.0.0
      setting :logger_constructor, default: Dry.method(:Logger)

      # @!attribute [rw] options
      #   Sets or returns a hash of options to pass to the {logger_constructor} when initializing
      #   the logger.
      #
      #   Defaults to `[]`
      #
      #   @return [Hash]
      #
      #   @api public
      #   @since 2.0.0
      setting :options, default: {}

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
                           else
                             :rack
                           end
      end

      # Returns a new instance of the logger.
      #
      # @return [logger_class]
      #
      # @api public
      # @since 2.0.0
      def instance
        logger_constructor.call(app_name.name, **logger_constructor_opts)
      end

      private

      # @api private
      def logger_constructor_opts
        {stream: stream,
          level: level,
          formatter: formatter,
          filters: filters,
          template: template,
          **options}
      end

      # @api private
      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      # @api private
      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
