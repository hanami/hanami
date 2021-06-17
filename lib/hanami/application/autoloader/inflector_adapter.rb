module Hanami
  class Application
    module Autoloader
      # Allows the Hanami standard inflector (from dry-inflector) to be used with Zeitwerk
      class InflectorAdapter
        def initialize(inflector)
          @inflector = inflector
        end

        def camelize(basename, _abspath)
          # Discard unused `_abspath` argument before calling our own inflector's
          # `#camelize` (which takes only one argument)
          inflector.camelize(basename)
        end

        private

        attr_reader :inflector
      end
    end
  end
end
