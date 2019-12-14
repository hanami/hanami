# frozen_string_literal: true

require "dry/core/constants"
require_relative "settings/definition"
require_relative "settings/struct"

module Hanami
  class Application
    # Application settings
    #
    # @since 2.0.0
    module Settings
      Undefined = Dry::Core::Constants::Undefined

      def self.build(loader, loader_options, &definition_block)
        definition = Definition.new(&definition_block)
        settings = loader.new(**loader_options).call(definition.settings)

        Struct[settings.keys].new(settings)
      end
    end
  end
end
