# frozen_string_literal: true

require "dry/configurable"

module Hanami
  module Providers
    class DB < Hanami::Provider::Source
      # @api public
      # @since 2.2.0
      class Adapter
        include Dry::Configurable

        # @api public
        # @since 2.2.0
        setting :plugins, mutable: true

        # @api private
        def initialize(...)
          @skip_defaults = Hash.new(false)
        end

        # @api public
        # @since 2.2.0
        def skip_defaults(setting_name = nil)
          @skip_defaults[setting_name] = true
        end

        # @api private
        private def skip_defaults?(setting_name = nil)
          @skip_defaults[setting_name]
        end

        # @api private
        def configure_for_database(database_url)
        end

        # @api public
        # @since 2.2.0
        def plugin(**plugin_spec, &config_block)
          plugins << [plugin_spec, config_block]
        end

        # @api public
        # @since 2.2.0
        def plugins
          config.plugins ||= []
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
          config.plugins = nil
          self
        end
      end
    end
  end
end
