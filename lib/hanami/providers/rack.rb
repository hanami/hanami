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
        Dry::Monitor.load_extensions(:rack)

        # Explicitly register the Rack middleware events on our notifications bus. The Dry::Monitor
        # rack extension (activated above) does register these globally, but if the notifications
        # bus has been used before this provider loads, then it will have created its own separate
        # locally copy of all registered events as of that moment in time, which will not included
        # the Rack events globally reigstered above.
        notifications = target["notifications"]
        notifications.register_event(Dry::Monitor::Rack::Middleware::REQUEST_START)
        notifications.register_event(Dry::Monitor::Rack::Middleware::REQUEST_STOP)
        notifications.register_event(Dry::Monitor::Rack::Middleware::REQUEST_ERROR)
      end

      # @api private
      def start
        target.start :logger

        monitor_middleware = Dry::Monitor::Rack::Middleware.new(
          target["notifications"],
          clock: Dry::Monitor::Clock.new(unit: :microsecond)
        )

        rack_logger = Hanami::Web::RackLogger.new(target[:logger], env: target.env)
        rack_logger.attach(monitor_middleware)

        register "monitor", monitor_middleware
      end
    end
  end
end
