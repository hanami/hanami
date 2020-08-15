Hanami.application.register_bootable :rack_monitor do |container|
  start do
    require "dry/monitor"
    require "dry/monitor/rack/middleware"

    middleware = Dry::Monitor::Rack::Middleware.new(container[:notifications])

    register :rack_monitor, middleware
  end
end
