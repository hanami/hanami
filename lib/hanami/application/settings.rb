module Hanami
  class Application
    class Settings
      def self.build(loader, loader_options, &settings_definition)
        definition = Definition.new(&settings_definition)
        loader.new(loader_options).call(definition)
      end

      class Definition
        attr_reader :settings

        def initialize(&block)
          @settings = []
          instance_eval(&block)
        end

        def setting(name, *args)
          @settings << [name, args]
        end

        def keys
          @settings.map { |(name, _)| name }
        end
      end

      class Loader
        attr_reader :options

        def initialize(options = {})
          @options = options
        end

        def call(settings_definition)
          begin
            require "dotenv"
            Dotenv.load
          rescue LoadError
          end

          settings_klass = Class.new

          settings_definition.keys.each do |key|
            settings_klass.attr_reader key
          end

          settings = settings_klass.new

          errors = {}

          settings_definition.settings.each do |(name, args)|
            begin
              settings.instance_variable_set(:"@#{name}", fetch_setting(name, args))
            rescue StandardError => e
              errors[name] = e
            end
          end

          raise InvalidSettingsError, errors unless errors.empty?

          settings.freeze
        end

        private

        def fetch_setting(name, args)
          env_key = name.to_s.upcase

          return ENV[env_key] if args.none?

          if args[0].is_a?(Hash)
            raise "options are not supported by the default settings loader. Use a custom settings loader to handle options."
          else
            args[0].(ENV[env_key])
          end
        end
      end

      InvalidSettingsError = Class.new(StandardError) do
        def initialize(setting_errors)
          message = <<~STR
            Could not initialize settings. The following settings were invalid:

            #{setting_errors.map { |setting, message| "#{setting}: #{message}" }.join("\n")}
          STR
          super(message)
        end
      end
    end
  end
end
