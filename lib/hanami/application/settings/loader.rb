# frozen_string_literal: true

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

        UnsupportedSettingArgumentError = Class.new(StandardError) do
          def initialize(setting_name, arguments)
            @setting_name = setting_name
            @arguments = arguments
          end

          def to_s
            <<~STR.strip
              Unsupported arguments #{@arguments.inspect} for setting +#{@setting_name}+
            STR
          end
        end

        def initialize(*)
        end

        def call(defined_settings)
          load_dotenv

          errors = load_settings(defined_settings)

          raise InvalidSettingsError, errors if errors.any?

          Settings.config.values
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

        def load_settings(defined_settings) # rubocop:disable Metrics/MethodLength
          defined_settings.reduce({}) { |errors, (name, args)|
            begin
              value = resolve_setting(name, args)
              Settings.setting(name, value)
              errors
            rescue => exception # rubocop:disable Style/RescueStandardError
              if exception.is_a?(UnsupportedSettingArgumentError) # rubocop: disable Style/GuardClause
                raise exception
              else
                errors.merge(name => exception)
              end
            end
          }
        end

        def resolve_setting(name, args)
          value = ENV.fetch(name.to_s.upcase) { Undefined }

          if args.none?
            value
          elsif args[0]&.respond_to?(:call)
            args[0].call(value)
          else
            raise UnsupportedSettingArgumentError.new(name, args)
          end
        end
      end
    end
  end
end
