module Lotus
  class Middleware
    def initialize(application)
      configuration = application.configuration
      routes        = application.routes

      # FIXME make urls configurable
      # FIXME make root configurable
      @builder = ::Rack::Builder.new
      @builder.use Rack::Static,
        urls: ['/favicon.ico', '/stylesheets', '/images', '/javascripts', '/fonts'],
        root: configuration.root.join('public').to_s
      @builder.run routes
    end

    def call(env)
      @builder.call(env)
    end
  end
end
