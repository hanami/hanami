# frozen_string_literal: true

require "dry/inflector"
require "dry/monitor" # from dry-web, TODO: remove
require "dry/monitor/rack/middleware"
require "dry/system/container"
require "dry/system/components"
require "pathname"
require_relative "../web/rack_logger"

module Hanami
  class Application
    class Container < Dry::System::Container
      # TODO: pass settings in from Hanami::Application.config when setting up container
      setting :inflector, Dry::Inflector.new, reader: true

      setting :web do
        setting :logging do
          setting :filter_params, %w[_csrf password password_confirmation]
        end
      end

      use :env, inferrer: -> { ENV.fetch("RACK_ENV", "development").to_sym }
      use :logging
      use :notifications
      use :monitoring

      after :configure do
        register_inflector

        register_rack_monitor
        attach_rack_logger

        load_paths! "lib"
      end

      class << self
        private

        def register_inflector
          return self if key?(:inflector)
          register :inflector, inflector
        end

        def register_rack_monitor
          return self if key?(:rack_monitor)
          register :rack_monitor, Dry::Monitor::Rack::Middleware.new(self[:notifications])
          self
        end

        def attach_rack_logger
          Web::RackLogger.new(
            self[:logger],
            filter_params: config.web.logging.filter_params,
          ).attach(self[:rack_monitor])

          self
        end
      end
    end


    # Hanami private IoC
    #
    # @since 2.0.0
    class OldContainer < Dry::System::Container
      configure do |config|
        config.root = Pathname.new(Dir.pwd)
      end

      boot(:env) do |c|
        init do
          begin
            require "dotenv"
          rescue LoadError # rubocop:disable Lint/HandleExceptions
          end

          Dotenv.load(c.root.join(".env")) if defined?(Dotenv)
        end
      end

      boot(:lib) do |c|
        init do
          $LOAD_PATH.unshift c.root.join("lib")
          Hanami::Utils.require!(c.root.join("lib", "**", "*.rb"))
        end
      end

      boot(:configuration) do |c|
        init do
          require c.root.join("config", "application").to_s
        end

        start do
          register(:configuration, Hanami.application_class.configuration.finalize)
        end
      end

      boot(:logger) do |c|
        init do
          require "hanami/logger"
        end

        start do
          use :configuration
          register(:logger, Hanami::Logger.new(c[:configuration].logger))
        end
      end

      boot(:routes) do |c|
        init do
          require c.root.join("config", "routes").to_s
        end

        start do
          register(:routes, Hanami.application_class.routes)
        end
      end

      boot(:apps) do |c|
        start do
          use :routes

          register(:apps, c[:routes].apps)
        end
      end

      boot(:actions) do |c|
        init do
          use :configuration
          use :apps

          c[:apps].each do |app|
            require c.root.join("apps", app.to_s, "action")

            namespace = Utils::String.classify("#{app}::Actions")
            namespace = Utils::Class.load!(namespace)

            configuration = Controller::Configuration.new do |config|
              config.cookies                 = c[:configuration].cookies.options
              config.default_headers         = c[:configuration].security.to_hash
              config.default_request_format  = c[:configuration].default_request_format
              config.default_response_format = c[:configuration].default_response_format
            end

            register(:"apps.#{app}.actions.namespace", namespace)
            register(:"apps.#{app}.actions.configuration", configuration)
          end
        end
      end

      boot(:code) do |c|
        init do
          use :configuration
          use :apps
          use :actions

          apps = c[:apps].join(",")
          Hanami::Utils.require!(c.root.join("apps", "{#{apps}}", "**", "*.rb"))
        end
      end
    end
  end
end
