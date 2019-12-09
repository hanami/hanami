require "hanami/utils/basic_object"

module Hanami
  class Application
    module Settings
      class Definition < Hanami::Utils::BasicObject
        attr_reader :settings

        def initialize(&block)
          @settings = []
          instance_eval(&block)
        end

        def setting(name, *args)
          @settings << [name, args]
        end
      end
    end
  end
end
