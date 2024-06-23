# frozen_string_literal: true

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

        # @api private
        def configure_for_database(database_url)
        end

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

        # @api private
        def gateway_cache_keys
          gateway_options
        end

        # @api private
        def gateway_options
          {}
        end

        # @api public
        # @since 2.2.0
        def clear
          config.plugins.clear
          self
        end
      end
    end
  end
end
