# frozen_string_literal: true

module Hanami
  # @api private
  module Web
    # Rack logger for Hanami apps
    #
    # @api private
    # @since 2.0.0
    class RackLogger
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

      # @api private
      # @since 2.0.0
      def initialize(logger)
        @logger = logger
      end

      # @api private
      # @since 2.0.0
      def attach(rack_monitor)
        rack_monitor.on :stop do |event|
          log_request event[:env], event[:status], event[:time]
        end

        rack_monitor.on :error do |event|
          log_exception event[:exception]
        end
      end

      # @api private
      # @since 2.0.0
      def log_request(env, status, elapsed)
        data = {
          verb: env[REQUEST_METHOD],
          status: status,
          elapsed: "#{elapsed}ms",
          ip: env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR],
          path: env[SCRIPT_NAME] + env[PATH_INFO].to_s,
          length: extract_content_length(env),
          params: env[ROUTER_PARAMS],
          time: Time.now,
        }

        logger.info(data)
      end

      # @api private
      # @since 2.0.0
      def log_exception(exception)
        logger.error exception.message
        logger.error exception.backtrace.join("\n")
      end

      private

      attr_reader :logger

      def extract_content_length(env)
        value = env[CONTENT_LENGTH]
        !value || value.to_s == "0" ? "-" : value
      end
    end
  end
end
