module Hanami
  class Application
    module Settings
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
              define_method(name) do
                @settings[name]
              end unless reserved?(name)
            end
          end
        end

        def initialize(settings)
          @settings = settings.freeze
        end

        def [](name)
          if !self.class.setting_names.include?(name)
            raise ArgumentError, "Unknown setting +#{name}+"
          elsif self.class.reserved?(name)
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
