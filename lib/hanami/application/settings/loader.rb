# frozen_string_literal: true

require "dry/core/constants"

module Hanami
  class Application
    module Settings
      # Default application settings loader. Uses dotenv (if available) to load
      # .env files and then loads settings from ENV.
      #
      # @since 2.0.0
      # @api private
      class Loader
        InvalidSettingsError = Class.new(StandardError) do
          def initialize(errors)
            @errors = errors
          end

          def to_s
            <<~STR.strip
              Could not initialize settings. The following settings were invalid:

              #{@errors.map { |setting, message| "#{setting}: #{message}" }.join("\n")}
            STR
          end
        end

        def initialize(*)
        end

        def load(config)
          load_dotenv

          errors = load_settings!(config)

          raise InvalidSettingsError, errors if errors.any?

          config
        end

        private

        def load_dotenv
          require "dotenv"
          Dotenv.load(*dotenv_files) if defined?(Dotenv)
        rescue LoadError # rubocop:disable Lint/SuppressedException
        end

        def dotenv_files
          [
            ".env.#{Hanami.env}.local",
            (".env.local" unless Hanami.env?(:test)),
            ".env.#{Hanami.env}",
            ".env"
          ].compact
        end

        def load_settings!(config) # rubocop:disable Metrics/MethodLength
          config._settings.map(&:name).each_with_object({}) { |name, errors|
            begin
              config[name] = ENV.fetch(name.to_s.upcase) { Dry::Core::Constants::Undefined }
            rescue => exception
              errors[name] = exception
            end
          }
        end
      end
    end
  end
end
