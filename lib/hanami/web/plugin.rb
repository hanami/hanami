# frozen_string_literal: true

require "dry/monitor/rack/middleware"
require "dry/system/plugins"
require_relative "endpoint_resolver"
require_relative "rack_logger"

module Hanami
  module Web
    module Plugin
      def self.extended(system)
        super

        system.setting :web do
          setting :routing do
            setting :endpoint_resolver, EndpointResolver
            setting :action_key_namespace, "web.actions"
          end

          setting :logging do
            setting :filter_params, %w[_csrf password password_confirmation]
          end
        end

        system.after :configure do
          register_rack_monitor
          attach_rack_logger
        end
      end

      def register_rack_monitor
        return self if key?(:rack_monitor)
        register :rack_monitor, Dry::Monitor::Rack::Middleware.new(self[:notifications])
        self
      end

      def attach_rack_logger
        RackLogger.new(self[:logger], filter_params: config.web.logging.filter_params).attach(self[:rack_monitor])
        self
      end
    end

    # TODO: I wonder if want to find a way to namespace plugins... "web" is a
    # very generic name.
    Dry::System::Plugins.register :web, Plugin
  end
end
