# frozen_string_literal: true

module Hanami
  class Application
    module Settings
      # Application settings struct
      #
      # When the application loads settings, a struct subclass is created for
      # the settings defined specifically for the application, then initialized
      # with those settings and their values
      #
      # @since 2.0.0
      # @api public
      class Struct
        class << self
          def [](names)
            Class.new(self) do
              @setting_names = names

              define_singleton_method(:setting_names) do
                @setting_names
              end

              define_readers
            end
          end

          def reserved?(name)
            instance_methods.include?(name)
          end

          private

          def define_readers
            setting_names.each do |name|
              next if reserved?(name)

              define_method(name) do
                @settings[name]
              end
            end
          end
        end

        def initialize(settings)
          @settings = settings.freeze
        end

        def [](name)
          raise ArgumentError, "Unknown setting +#{name}+" unless self.class.setting_names.include?(name)

          if self.class.reserved?(name)
            @settings[name]
          else
            public_send(name)
          end
        end

        def to_h
          @settings.to_h
        end
      end
    end
  end
end
