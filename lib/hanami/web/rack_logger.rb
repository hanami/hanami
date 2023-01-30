# frozen_string_literal: true

module Hanami
  # @api private
  module Web
    # Rack logger for Hanami apps
    #
    # @api private
    # @since 2.0.0
    class RackLogger
      EMPTY_PARAMS = {}.freeze
      private_constant :EMPTY_PARAMS

      REQUEST_METHOD = "REQUEST_METHOD"
      private_constant :REQUEST_METHOD

      HTTP_X_FORWARDED_FOR = "HTTP_X_FORWARDED_FOR"
      private_constant :HTTP_X_FORWARDED_FOR

      REMOTE_ADDR = "REMOTE_ADDR"
      private_constant :REMOTE_ADDR

      SCRIPT_NAME = "SCRIPT_NAME"
      private_constant :SCRIPT_NAME

      PATH_INFO = "PATH_INFO"
      private_constant :PATH_INFO

      ROUTER_PARAMS = "router.params"
      private_constant :ROUTER_PARAMS

      CONTENT_LENGTH = "Content-Length"
      private_constant :CONTENT_LENGTH

      MILISECOND = "ms"
      private_constant :MILISECOND

      MICROSECOND = "µs"
      private_constant :MICROSECOND

      # Dynamic extension used in development and test environments
      # @api private
      module Development
        private

        # @since 2.0.0
        # @api private
        def data(env, status:, elapsed:)
          payload = super
          payload.delete(:elapsed_unit)
          payload[:elapsed] = elapsed > 1000 ? "#{elapsed / 1000}ms" : "#{elapsed}#{MICROSECOND}"
          payload
        end
      end

      # @api private
      # @since 2.0.0
      def initialize(logger, env: :development)
        @logger = logger
        extend(Development) if %i[development test].include?(env)
      end

      # @api private
      # @since 2.0.0
      def attach(rack_monitor)
        rack_monitor.on :stop do |event|
          log_request event[:env], event[:status], event[:time]
        end

        rack_monitor.on :error do |event|
          # TODO: why we don't provide time on error?
          log_exception event[:env], event[:exception], 500, 0
        end
      end

      # @api private
      # @since 2.0.0
      def log_request(env, status, elapsed)
        logger.tagged(:rack) do
          logger.info(data(env, status: status, elapsed: elapsed))
        end
      end

      # @api private
      # @since 2.0.0
      def log_exception(env, exception, status, elapsed)
        logger.tagged(:rack) do
          logger.error(exception, **data(env, status: status, elapsed: elapsed))
        end
      end

      private

      attr_reader :logger

      # @api private
      # @since 2.0.0
      def data(env, status:, elapsed:)
        {
          verb: env[REQUEST_METHOD],
          status: status,
          ip: env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR],
          path: "#{env[SCRIPT_NAME]}#{env[PATH_INFO]}",
          length: extract_content_length(env),
          params: env.fetch(ROUTER_PARAMS, EMPTY_PARAMS),
          elapsed: elapsed,
          elapsed_unit: MICROSECOND,
        }
      end

      # @api private
      # @since 2.0.0
      def extract_content_length(env)
        value = env[CONTENT_LENGTH]
        !value || value.to_s == "0" ? "-" : value
      end
    end
  end
end
