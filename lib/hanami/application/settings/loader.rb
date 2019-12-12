require "dry/core/constants"

module Hanami
  class Application
    module Settings
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

        Undefined = Dry::Core::Constants::Undefined

        def initialize(*)
        end

        def call(defined_settings)
          load_dotenv

          settings, errors = load_settings(defined_settings)

          if errors.any?
            raise InvalidSettingsError, errors
          else
            settings
          end
        end

        private

        def load_dotenv
          begin
            require "dotenv"
            Dotenv.load if defined?(Dotenv)
          rescue LoadError
          end
        end

        def load_settings(defined_settings)
          defined_settings.each_with_object([{}, {}]) { |(name, args), (settings, errors)|
            begin
              settings[name] = resolve_setting(name, args)
            rescue => e
              if e.is_a?(UnsupportedSettingArgumentError)
                raise e
              else
                errors[name] = e
              end
            end
          }
        end

        def resolve_setting(name, args)
          value = ENV.fetch(name.to_s.upcase) { Undefined }

          if args.none?
            value
          elsif args[0]&.respond_to?(:call)
            args[0].(value)
          else
            raise UnsupportedSettingArgumentError.new(name, args)
          end
        end
      end
    end
  end
end
