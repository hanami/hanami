module Lotus
  class Middleware
    def initialize(application)
      configuration = application.configuration
      routes        = application.routes

      @builder = ::Rack::Builder.new
      @builder.use Rack::Static,
        urls: configuration.assets.entries,
        root: configuration.assets
      @builder.run routes
    end

    def call(env)
      @builder.call(env)
    end
  end
end
