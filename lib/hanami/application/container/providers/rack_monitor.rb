# frozen_string_literal: true

Hanami.application.register_provider :rack_monitor do
  prepare do
    require "dry/monitor"
  end

  start do
    register :rack_monitor, Dry::Monitor::Rack::Middleware.new(target[:notifications])
  end
end
