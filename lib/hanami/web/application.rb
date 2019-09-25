# frozen_string_literal: true

require "rack"
require "hanami/controller"
require_relative "router"

module Hanami
  module Web
    class Application
      def initialize(application, &routes)
        resolver = application.config.web.routing.endpoint_resolver.new(
          application: application,
          namespace: application.config.web.routing.action_key_namespace,
        )

        router = Router.new(
          application: application,
          endpoint_resolver: resolver,
          &routes
        )

        @app = Rack::Builder.new do
          use application[:rack_monitor]

          router.middlewares.each do |(*middleware, block)|
            use(*middleware, &block)
          end

          run router
        end
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
