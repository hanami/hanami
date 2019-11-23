# frozen_string_literal: true

require "json"
require "rack/request"
require "hanami/utils/hash"

module Hanami
  module Web
    # Rack logger for Hanami applications
    class RackLogger
      attr_reader :logger
      attr_reader :filter_params

      def initialize(logger, filter_params: [])
        @logger = logger
        @filter_params = filter_params
      end

      def attach(rack_monitor)
        rack_monitor.on :stop do |env:, status:, time:|
          log_request env, status, time
        end

        rack_monitor.on :error do |event|
          log_exception event[:exception]
        end
      end

      # rubocop:disable Metrics/MethodLength
      def log_request(env, status, time)
        data = {
          http: env[HTTP_VERSION],
          verb: env[REQUEST_METHOD],
          status: status,
          ip: env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR],
          path: env[SCRIPT_NAME] + env[PATH_INFO].to_s,
          length: extract_content_length(env),
          params: extract_params(env),
          elapsed: time,
        }

        logger.info JSON.generate(data)
      end
      # rubocop:enable Metrics/MethodLength

      def log_exception(exception)
        logger.error exception.message
        logger.error exception.backtrace.join("\n")
      end

      private

      HTTP_VERSION = "HTTP_VERSION"
      REQUEST_METHOD = "REQUEST_METHOD"
      HTTP_X_FORWARDED_FOR = "HTTP_X_FORWARDED_FOR"
      REMOTE_ADDR = "REMOTE_ADDR"
      SCRIPT_NAME = "SCRIPT_NAME"
      PATH_INFO = "PATH_INFO"
      RACK_ERRORS = "rack.errors"
      QUERY_HASH = "rack.request.query_hash"
      FORM_HASH = "rack.request.form_hash"
      ROUTER_PARAMS = "router.params"
      CONTENT_LENGTH = "Content-Length"

      def extract_content_length(env)
        value = env[CONTENT_LENGTH]
        !value || value.to_s == "0" ? "-" : value
      end

      def extract_params(env)
        result = env.fetch(QUERY_HASH, {})
        result.merge!(env.fetch(FORM_HASH, {}))
        result.merge!(Hanami::Utils::Hash.deep_stringify(env.fetch(ROUTER_PARAMS, {})))
        result
      end

      FILTERED = "[FILTERED]"

      # rubocop:disable Metrics/MethodLength
      def filter(params)
        params.each_with_object({}) do |(k, v), h|
          if filter_params.include?(k)
            h.update(k => FILTERED)
          elsif v.is_a?(Hash)
            h.update(k => filter(v))
          elsif v.is_a?(Array)
            h.update(k => v.map { |m| m.is_a?(Hash) ? filter(m) : m })
          else
            h[k] = v
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
