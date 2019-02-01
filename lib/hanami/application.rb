# frozen_string_literal: true

require "hanami/configuration"
require "hanami/routes"
require "hanami/router"

module Hanami
  # Hanami application
  #
  # @since 2.0.0
  class Application
    @_mutex = Mutex.new

    def self.inherited(app_class)
      @_mutex.synchronize do
        app_class.class_eval do
          @_mutex         = Mutex.new
          @_configuration = Hanami::Configuration.new(env: Hanami.env)

          extend ClassMethods
          include InstanceMethods
        end

        Hanami.application_class = app_class
      end
    end

    # Class method interface
    #
    # @since 2.0.0
    module ClassMethods
      def configuration
        @_configuration
      end

      alias config configuration

      def routes(&blk)
        @_mutex.synchronize do
          if blk.nil?
            raise "Hanami.application_class.routes not configured" unless defined?(@_routes)

            @_routes
          else
            @_routes = Routes.new(&blk)
          end
        end
      end
    end

    # Instance method interface
    #
    # @since 2.0.0
    module InstanceMethods
      def initialize(configuration: self.class.configuration, routes: self.class.routes)
        @app = Rack::Builder.new do
          configuration.for_each_middleware do |m, *args|
            use m, *args
          end

          run Hanami::Router.new(**configuration.router_settings, &routes)
        end
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
