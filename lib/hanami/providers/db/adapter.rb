require "dry/configurable"

module Hanami
  module Providers
    class DB < Dry::System::Provider::Source
      # @api public
      # @since 2.2.0
      class Adapter
        include Dry::Configurable

        # @api public
        # @since 2.2.0
        setting :plugins, default: []

        # TODO: move to SQL adapter-specific class
        # @api public
        # @since 2.2.0
        setting :extensions, default: []

        # @api public
        # @since 2.2.0
        def plugin(**plugin_spec, &config_block)
          config.plugins << [plugin_spec, config_block]
        end

        # @api public
        # @since 2.2.0
        def plugins
          config.plugins
        end

        # @api public
        # @since 2.2.0
        def extension(*extensions)
          config.extensions += extensions
        end

        # @api public
        # @since 2.2.0
        def extensions
          config.extensions
        end

        # @api private
        # @since 2.2.0
        def gateway_cache_keys
          gateway_options
        end

        # @api private
        # @since 2.2.0
        def gateway_options
          {extensions: config.extensions}
        end

        # @api private
        # @since 2.2.0
        def clear
          config.plugins.clear
          config.extensions.clear
          self
        end
      end
    end
  end
end
