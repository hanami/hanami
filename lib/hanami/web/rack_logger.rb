# frozen_string_literal: true

require "json"
require "rack/request"

module Hanami
  module Web
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

      def log_request(env, status, time)
        request = Rack::Request.new(env)

        params = request.GET
        params = params.merge(Hash(request.POST))

        # TODO: support both roda and hanami params
        json_params = Hash(request.get_header("roda.json_params"))
        params = params.merge(json_params)

        data = {
          method: request.request_method,
          path: request.path,
          for: request.get_header("REMOTE_ADDR"),
          status: status,
          duration: time,
          params: filter(params),
        }

        logger.info JSON.generate(data)
      end

      def log_exception(e)
        logger.error e.message
        logger.error (e.backtrace).join("\n")
      end

      private

      FILTERED = "[FILTERED]"

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
    end
  end
end
