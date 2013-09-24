require 'lotus/configuration'

module Lotus
  # TODO remove
  module Rack
    class Static < ::Rack::Static
      def initialize(app, options = {})
        super
        @file_server = Lotus::Rack::File.new(options[:root] || Dir.pwd, @headers)
      end
    end

    class File < ::Rack::File
      def serving(env)
        Lotus::HTTP::Response.fabricate(super)
      end

      def available?
        begin
          F.file?(@path) && F.readable?(@path)
        rescue SystemCallError
          false
        end
      end

      def empty?
        not available?
      end
    end
  end

  module Routing
    class DefaultApp
      DEFAULT_CODE = 404

      def call(env)
        HTTP::Response.new(HTTP::Response::NullAction.new).tap do |response|
          response.status, _ = Http::Status.for_code(DEFAULT_CODE)
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
      middleware.call(env).tap do |response|
        response.body = view.render(response) if response.body.empty?
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

    def middleware
      @middleware ||= begin
        builder = ::Rack::Builder.new
        builder.use Rack::Static, urls: ['/favicon.ico', '/stylesheets', '/images', '/javascripts'], root: config.root.join('public').to_s
        builder.run @routes
        builder
      end
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
      middleware

      view.layout = :application
      view.load!
    end

    private
    def config
      self.class.config
    end
  end
end
