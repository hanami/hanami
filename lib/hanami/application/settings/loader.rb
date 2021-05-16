# frozen_string_literal: true

require "dry/core/constants"

module Hanami
  class Application
    module Settings
      # Application settings loader.
      #
      # Fetches settings from store before delegating to the configuration
      # class. Collects all errors and joins them into a single exception.
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

        def load(config, store)
          errors = load_settings!(config, store)

          raise InvalidSettingsError, errors if errors.any?

          config
        end

        private

        def load_settings!(config, store)
          config._settings.map(&:name).each_with_object({}) do |name, errors|
            config[name] = store.fetch(name) { Dry::Core::Constants::Undefined }
          rescue => e # rubocop:disable Style/RescueStandardError
            errors[name] = e
          end
        end
      end
    end
  end
end
