# frozen_string_literal: true

require "dry/system/container"

module Hanami
  # Hanami private IoC
  #
  # @since 2.0.0
  class Container < Dry::System::Container
    boot(:root) do
      start do
        register(:root, Hanami.root)
      end
    end

    boot(:env) do |c|
      init do
        use :root

        begin
          require "dotenv"
        rescue LoadError # rubocop:disable Lint/HandleExceptions
        end

        Dotenv.load(c[:root].join(".env")) if defined?(Dotenv)
      end
    end

    boot(:lib) do |c|
      init do
        use :root

        $LOAD_PATH.unshift root.join("lib")
        Hanami::Utils.require!(c[:root].join("lib", "**", "*.rb"))
      end
    end

    boot(:environment) do |c|
      init do
        use :root

        require c[:root].join("config", "environment").to_s
      end
    end

    boot(:configuration) do
      start do
        use :environment

        register(:configuration, Hanami.application.configuration.finalize)
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
        require c[:root].join("config", "routes").to_s
      end

      start do
        register(:routes, Hanami.application.routes)
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
          require c[:root].join("apps", app.to_s, "action")

          namespace = Utils::String.classify("#{app}::Actions")
          namespace = Utils::Class.load!(namespace)
          # action    = Utils::Class.load!("#{namespace}::Action")
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
        use :root
        use :environment
        use :apps
        use :actions

        apps = c[:apps].join(",")
        Hanami::Utils.require!(c[:root].join("apps", "{#{apps}}", "**", "*.rb"))
      end
    end
  end
end
