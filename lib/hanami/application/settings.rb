require_relative "settings/definition"
require_relative "settings/struct"

module Hanami
  class Application
    module Settings
      def self.build(loader, loader_options, &definition_block)
        definition = Definition.new(&definition_block)
        settings = loader.new(**loader_options).call(definition)

        Struct[settings.keys].new(settings)
      end
    end
  end
end
