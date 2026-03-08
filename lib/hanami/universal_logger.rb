# frozen_string_literal: true

require "json"

module Hanami
  # An adapter that optionally wraps the logger configured for a Hanami app. Ensures that both
  # structured and tagged logging can be used across the Hanami framework.
  #
  # Provides `.call` as its main entrypoint, expecting a logger object. If a compatible logger is
  # given (such as the Dry Logger instance provided by default in Hanami apps), then that logger is
  # returned directly and not wrapped.
  #
  # If a non-compatible logger is given, then it will be wrapped by an instance of UniversalLogger,
  # which adapts a structured and tagged logging API to the given logger.
  #
  # This leads to two levels of logger enhancement:
  #
  # 1. Structured-capable loggers (accepts keyword arguments, but no `#tagged` method): tags are are
  #    provided as a `:tags` keyword argument when logging.
  # 2. Legacy loggers (such as the Ruby standard `Logger`, no keyword arguments, no `#tagged`
  #    method): messages are logged as JSON, with tags under a `"tags"` key.
  #
  # This adapter is used for all loggers configured in Hanami apps.
  #
  # @api public
  # @since x.x.x
  class UniversalLogger
    class << self
      # Wrap a logger if needed, or return it as-is if fully compatible.
      #
      # @param logger [Object] the logger to wrap
      # @return [Object, UniversalLogger] the original logger or wrapped logger
      #
      # @api private
      def call(logger)
        return logger if compatible_logger?(logger)

        new(logger)
      end

      # @api private
      alias_method :[], :call

      # @api private
      def compatible_logger?(logger)
        structured_logger?(logger) && tagged_logger?(logger)
      end

      # @api private
      def tagged_logger?(logger)
        logger.respond_to?(:tagged)
      end

      # @api private
      def structured_logger?(logger)
        logger.respond_to?(:info) &&
          logger.method(:info).parameters.any? { |(type, _)| type == :keyrest }
      end
    end

    # @api public
    # @since x.x.x
    attr_reader :logger

    # @api private
    def initialize(logger)
      @logger = logger
      @structured_logger = self.class.structured_logger?(logger)
      @tags_thread_key = :"hanami_universal_logger_tags_#{object_id}"
    end

    # @api private
    LOG_LEVEL_METHODS = %i[debug info warn error fatal unknown].freeze
    private_constant :LOG_LEVEL_METHODS

    # @!method debug(message = nil, **payload, &blk)
    #   Logs a debug message.
    #
    #   @param message [String, nil] the log message
    #   @param payload [Hash] structured data to include in the log entry
    #   @yieldreturn [Hash] additional payload data to merge
    #   @return [void]
    #
    #   @api public
    #   @since x.x.x

    # @!method info(message = nil, **payload, &blk)
    #   Logs an info message.
    #
    #   @param message [String, nil] the log message
    #   @param payload [Hash] structured data to include in the log entry
    #   @yieldreturn [Hash] additional payload data to merge
    #   @return [void]
    #   @api public
    #   @since x.x.x

    # @!method warn(message = nil, **payload, &blk)
    #   Logs a warning message.
    #
    #   @param message [String, nil] the log message
    #   @param payload [Hash] structured data to include in the log entry
    #   @yieldreturn [Hash] additional payload data to merge
    #   @return [void]
    #
    #   @api public
    #   @since x.x.x

    # @!method error(message = nil, **payload, &blk)
    #   Logs an error message.
    #
    #   @param message [String, nil] the log message
    #   @param payload [Hash] structured data to include in the log entry
    #   @yieldreturn [Hash] additional payload data to merge
    #   @return [void]
    #
    #   @api public
    #   @since x.x.x

    # @!method fatal(message = nil, **payload, &blk)
    #   Logs a fatal message.
    #
    #   @param message [String, nil] the log message
    #   @param payload [Hash] structured data to include in the log entry
    #   @yieldreturn [Hash] additional payload data to merge
    #   @return [void]
    #
    #   @api public
    #   @since x.x.x

    # @!method unknown(message = nil, **payload, &blk)
    #   Logs a message with unknown severity.
    #
    #   @param message [String, nil] the log message
    #   @param payload [Hash] structured data to include in the log entry
    #   @yieldreturn [Hash] additional payload data to merge
    #   @return [void]
    #
    #   @api public
    #   @since x.x.x

    LOG_LEVEL_METHODS.each do |level|
      define_method(level) do |message = nil, **payload, &blk|
        _log(level, message, payload, &blk)
      end
    end

    # @api public
    # @since x.x.x
    def add(severity, message = nil, progname = nil, &blk)
      # Convert severity to a level symbol if it's an integer (the standard Logger uses integers).
      level = _severity_to_level(severity)

      payload = {}
      payload[:progname] = progname if progname

      _log(level, message, payload, &blk)
    end

    # @api public
    # @since x.x.x
    alias_method :log, :add

    # @api public
    # @since x.x.x
    def tagged(*tags)
      previous_tags = _current_tags
      self._current_tags = tags
      begin
        yield
      ensure
        self._current_tags = previous_tags
      end
    end

    private

    # Delegates any other methods to the wrapped logger.
    def method_missing(method, ...)
      if logger.respond_to?(method)
        logger.public_send(method, ...)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      logger.respond_to?(method, include_private) || super
    end

    # Maps a standard Logger severity integer (e.g. 1) to a level name (`:info`).
    #
    # We need this be able to support the basic `Logger#log` and `#add` methods in addition to the
    # named severity methods.
    def _severity_to_level(severity)
      return severity if severity.is_a?(Symbol)

      SEVERITY_MAP.fetch(severity, :unknown)
    end

    SEVERITY_MAP = {
      0 => :debug,   # Logger::DEBUG
      1 => :info,    # Logger::INFO
      2 => :warn,    # Logger::WARN
      3 => :error,   # Logger::ERROR
      4 => :fatal,   # Logger::FATAL
      5 => :unknown  # Logger::UNKNOWN
    }.freeze
    private_constant :SEVERITY_MAP

    def _log(level, message, payload, &blk)
      if @structured_logger
        _log_structured(level, message, payload, &blk)
      else
        _log_json(level, message, payload, &blk)
      end
    end

    def _log_structured(method, message, payload)
      payload = payload.merge(yield) if block_given?

      tags = _current_tags
      payload[:tags] = tags if tags && !tags.empty?

      logger.public_send(method, message, **payload)
    end

    def _log_json(method, message, payload)
      json_data =
        if block_given?
          yield
        else
          payload[:message] = message if message
          payload
        end

      tags = _current_tags
      json_data[:tags] = tags if tags && !tags.empty?

      logger.public_send(method, JSON.generate(json_data))
    end

    def _current_tags
      Thread.current[@tags_thread_key]
    end

    def _current_tags=(tags)
      Thread.current[@tags_thread_key] = tags
    end
  end
end
