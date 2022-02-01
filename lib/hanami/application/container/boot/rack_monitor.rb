# frozen_string_literal: true

Hanami.application.register_bootable :rack_monitor do
  start do
    require "dry/monitor"
    require "dry/monitor/rack/middleware"

    middleware = Dry::Monitor::Rack::Middleware.new(target[:notifications])

    register :rack_monitor, middleware
  end
end
