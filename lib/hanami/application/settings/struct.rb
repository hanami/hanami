require "hanami/utils/basic_object"

module Hanami
  class Application
    module Settings
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
    end
  end
end
