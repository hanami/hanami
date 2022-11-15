# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    # Provider source to register Rack integration components in Hanami slices.
    #
    # @see Hanami::Providers::Logger
    # @see Hanami::Web::RackLogger
    # @see https://github.com/rack/rack
    # @see https://dry-rb.org/gems/dry-monitor/
    #
    # @api private
    # @since 2.0.0
    class Rack < Dry::System::Provider::Source
      # @api private
      def prepare
        require "dry/monitor"
        require "hanami/web/rack_logger"

        Dry::Monitor.load_extensions(:rack)
      end

      # @api private
      def start
        target.start :logger

        notifications = target[:notifications]

        clock = Dry::Monitor::Clock.new(unit: :microsecond)
        monitor_middleware = Dry::Monitor::Rack::Middleware.new(notifications, clock: clock)

        rack_logger = Hanami::Web::RackLogger.new(target[:logger])
        rack_logger.attach(monitor_middleware)

        register "monitor", monitor_middleware
      end
    end
  end
end
