require 'lotus/configuration'

module Lotus
  # TODO remove
  module Routing
    class DefaultApp
      DEFAULT_CODE = 404

      def call(env)
        HTTP::Response.new(NullAction.new).tap do |response|
          response.status, response.body = Http::Status.for_code(DEFAULT_CODE)
        end
      end

      private
      class NullAction
        def exposures
          {}
        end
      end
    end
  end
  # END TODO remove

  class Application
    def self.configure(&blk)
      self.config = Configuration.new(&blk)
    end

    def initialize
      load!
    end

    def call(env)
      routes.call(env).tap do |response|
        response.body = view.render(response)
      end
    end

    protected
    attr_reader :routes

    class << self
      attr_accessor :config
    end

    def view
      Lotus::View
    end

    def load!
      view.config = config
      view.root   = config.root

      Dir.glob("#{ config.root }/**/*.rb").each do |file|
        require file unless file.match(config.excluded_load_paths)
      end

      resolver    = Lotus::Routing::EndpointResolver.new(suffix: config.controller_namespace)
      default_app = Lotus::Routing::DefaultApp.new
      @routes  = Lotus::Router.draw(resolver: resolver, default_app: default_app, &config.routes)

      view.layout = :application
      view.load!
    end

    private
    def config
      self.class.config
    end
  end
end
