# frozen_string_literal: true

require "dry/system/container"
require "pathname"

module Hanami
  class Application
    # Hanami private IoC
    #
    # @since 2.0.0
    class Container < Dry::System::Container
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
