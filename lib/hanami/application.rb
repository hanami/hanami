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

    def self.inherited(app)
      @_mutex.synchronize do
        app.class_eval do
          @_mutex         = Mutex.new
          @_configuration = Hanami::Configuration.new

          extend ClassMethods
          include InstanceMethods
        end

        Hanami.application = app
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
            raise "Hanami.application.routes not configured" unless defined?(@_routes)

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
      def initialize(routes: self.class.routes)
        @router = Hanami::Router.new(&routes)
      end
    end
  end
end
