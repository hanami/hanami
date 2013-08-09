require 'lotus/configuration'

module Lotus
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
        require file
      end

      resolver = Lotus::Routing::EndpointResolver.new(suffix: config.controller_namespace)
      @routes  = Lotus::Router.draw(resolver: resolver, &config.routes)

      view.layout = :application
      view.load!
    end

    private
    def config
      self.class.config
    end
  end
end
