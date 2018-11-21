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
        require c[:root].join("config", "action").to_s
      end
    end

    boot(:code) do |c|
      init do
        use :root
        use :environment

        Hanami::Utils.require!(c[:root].join("apps", "**", "*.rb"))
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
        use :code
        use :routes

        register(:apps, c[:routes].apps)
      end
    end
  end
end
