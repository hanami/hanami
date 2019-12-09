module Hanami
  class Application
    module Settings
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
    end
  end
end
