# frozen_string_literal: true

module Hanami
  class Application
    module Settings
      # Default application settings store.
      #
      # Uses dotenv (if available) to load .env files and then loads settings
      # from ENV.
      #
      # @since 2.0.0
      # @api private
      class DotenvStore
        def fetch(name, &block)
          ENV.fetch(name.to_s.upcase) { block.call }
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
            ".env.#{Hanami.env}.local",
            (".env.local" unless Hanami.env?(:test)),
            ".env.#{Hanami.env}",
            ".env"
          ].compact
        end
      end
    end
  end
end
