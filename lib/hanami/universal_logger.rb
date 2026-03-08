# frozen_string_literal: true

module Hanami
  # @since 2.1.0
  # @api private
  class UniversalLogger
    class << self
      # @since 2.1.0
      # @api private
      def call(logger)
        return logger if compatible_logger?(logger)

        new(logger)
      end

      # @since 2.1.0
      # @api private
      alias_method :[], :call

      private

      def compatible_logger?(logger)
        logger.respond_to?(:tagged) && accepts_entry_payload?(logger)
      end

      def accepts_entry_payload?(logger)
        logger.method(:info).parameters.any? { |(type, _)| type == :keyrest }
      end
    end

    # @since 2.1.0
    # @api private
    attr_reader :logger

    # @since 2.1.0
    # @api private
    def initialize(logger)
      @logger = logger
    end

    # @since 2.1.0
    # @api private
    def tagged(*, &blk)
      blk.call
    end

    # Logs the entry as JSON.
    #
    # This ensures a reasonable (and parseable) representation of our log payload structures for
    # loggers that are configured to wholly replace Hanami's default logger.
    #
    # @since 2.1.0
    # @api private
    def info(message = nil, **payload, &blk)
      logger.info do
        if blk
          JSON.generate(blk.call)
        else
          payload[:message] = message if message
          JSON.generate(payload)
        end
      end
    end

    # @see info
    #
    # @since 2.1.0
    # @api private
    def error(message = nil, **payload, &blk)
      logger.error do
        if blk
          JSON.generate(blk.call)
        else
          payload[:message] = message if message
          JSON.generate(payload)
        end
      end
    end
  end
end
