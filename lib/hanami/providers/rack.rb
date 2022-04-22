# frozen_string_literal: true

require "dry/system/provider/source"

module Hanami
  module Providers
    class Rack < Dry::System::Provider::Source
      def prepare
        require "dry/monitor/rack/middleware" # FIXME: this _used_ to be just "dry/monitor"
        require "hanami/web/rack_logger"
      end

      def start
        target.start :logger

        notifications = target[:notifications]

        monitor_middleware = Dry::Monitor::Rack::Middleware.new(notifications)

        rack_logger = Hanami::Web::RackLogger.new(target[:logger])
        rack_logger.attach(monitor_middleware)

        register "monitor", monitor_middleware
        register "logger", rack_logger
      end
    end
  end
end
