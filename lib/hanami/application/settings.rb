require "hanami/utils/basic_object"

module Hanami
  class Application
    module Settings
      def self.build(loader, loader_options, &settings_definition)
        definition = Definition.new(&settings_definition)
        settings = loader.new(loader_options).call(definition)

        Struct[settings.keys].new(settings)
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

        def call(definition)
          load_dotenv

          settings, errors = load_settings(definition)

          if errors.any?
            raise InvalidSettingsError, errors if errors.any?
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

        def load_settings(definition)
          definition.settings.each_with_object([{}, {}]) { |(name, args), (settings, errors)|
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

      class Struct < Hanami::Utils::BasicObject
        class << self
          def [](names)
            Class.new(self) do
              @setting_names = names
              define_readers
            end
          end

          private

          def define_readers
            @setting_names.each do |name|
              define_method(name) do
                @settings[name]
              end unless reserved?(name)
            end
          end

          def reserved?(name)
            reserved_names.include?(name)
          end

          def reserved_names
            @reserved_names ||= [
              instance_methods(false),
              superclass.instance_methods(false),
              %i[class public_send],
            ].reduce(:+)
          end
        end

        def initialize(settings)
          @settings = settings.freeze
        end

        def [](name)
          @settings[name]
        end

        def to_h
          @settings.to_h
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
