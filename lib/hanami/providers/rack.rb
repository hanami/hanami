# frozen_string_literal: true

require "dry/system/provider/source"

module Hanami
  module Providers
    class Rack < Dry::System::Provider::Source
      def prepare
        require "dry/monitor"
        require "hanami/web/rack_logger"

        Dry::Monitor.load_extensions(:rack)
      end

      def start
        target.start :logger

        notifications = target[:notifications]

        monitor_middleware = Dry::Monitor::Rack::Middleware.new(notifications)

        rack_logger = Hanami::Web::RackLogger.new(target[:logger])
        rack_logger.attach(monitor_middleware)

        register "monitor", monitor_middleware
      end
    end
  end
end
