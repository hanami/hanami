require "dry/configurable"

module Hanami
  module Providers
    class DB < Dry::System::Provider::Source
      # @api public
      # @since 2.2.0
      class Adapter
        include Dry::Configurable

        setting :plugins, default: {}

        # TODO: move to SQL adapter-specific class
        setting :extensions, default: []

        def plugin(**options, &block)
          config.plugins[options] = block
        end

        def clear
          config.plugins.clear
          config.extensions.clear
          self
        end
      end
    end
  end
end
