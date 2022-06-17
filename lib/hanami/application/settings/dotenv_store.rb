# frozen_string_literal: true

require "dry/core/constants"

module Hanami
  class Application
    class Settings
      # Default application settings store.
      #
      # Uses [dotenv](https://github.com/bkeepers/dotenv) (if available) to load
      # .env files and then loads settings from ENV. For a given `HANAMI_ENV`
      # environment, the following `.env` files are looked up in the following order:
      #
      # - .env.{environment}.local
      # - .env.local (except if the environment is `test`)
      # - .env.{environment}
      # - .env
      #
      # @since 2.0.0
      # @api private
      class DotenvStore
        Undefined = Dry::Core::Constants::Undefined

        attr_reader :store,
                    :hanami_env

        def initialize(store: ENV, hanami_env: Hanami.env)
          @store = store
          @hanami_env = hanami_env
        end

        def fetch(name, default_value = Undefined, &block)
          name = name.to_s.upcase
          args = (default_value == Undefined) ? [name] : [name, default_value]

          store.fetch(*args, &block)
        end

        def with_dotenv_loaded
          require "dotenv"
          Dotenv.load(*dotenv_files) if defined?(Dotenv)
          self
        rescue LoadError
          self
        end

        private

        def dotenv_files
          [
            ".env.#{hanami_env}.local",
            (".env.local" unless hanami_env == :test),
            ".env.#{hanami_env}",
            ".env"
          ].compact
        end
      end
    end
  end
end
