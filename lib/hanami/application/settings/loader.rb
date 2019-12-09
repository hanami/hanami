module Hanami
  class Application
    module Settings
      class Loader
        InvalidSettingsError = Class.new(StandardError) do
          def initialize(errors)
            @errors = errors
          end

          def message
            <<~STR
              Could not initialize settings. The following settings were invalid:

              #{errors.map { |setting, message| "#{setting}: #{message}" }.join("\n")}
            STR
          end
        end

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
            Dotenv.load
          rescue LoadError
          end
        end

        def load_settings(defined_settings)
          defined_settings.each_with_object([{}, {}]) { |(name, args), (settings, errors)|
            begin
              settings[name] = resolve_setting(name, args)
            rescue StandardError => e
              errors[name] = e
            end
          }
        end

        def resolve_setting(name, args)
          value = ENV[name.to_s.upcase]

          if args.none?
            value
          elsif args[0]&.respond_to?(:call)
            args[0].(ENV[env])
          else
            raise "Unsupported setting arguments: #{args.inspect}"
          end
        end
      end
    end
  end
end
