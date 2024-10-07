# frozen_string_literal: true

require "dry/configurable"
require "dry/core"

module Hanami
  module Providers
    class DB < Hanami::Provider::Source
      # @api public
      # @since 2.2.0
      class Gateway
        include Dry::Core::Constants
        include Dry::Configurable

        setting :database_url
        setting :adapter_name, default: :sql
        setting :adapter, mutable: true
        setting :connection_options, default: {}

        # @api public
        # @since 2.2.0
        def adapter(name = Undefined)
          return config.adapter if name.eql?(Undefined)

          if block_given?
            # If a block is given, explicitly configure the gateway's adapter
            config.adapter_name = name
            adapter = (config.adapter ||= Adapters.new_adapter(name))
            yield adapter
            adapter
          else
            # If an adapter name is given without a block, use the default adapter configured with
            # the same name
            config.adapter_name = adapter_name
          end
        end

        # @api public
        # @since 2.2.0
        def connection_options(**options)
          if options.any?
            config.connection_options.merge!(options)
          end

          config.connection_options
        end

        # @api public
        # @since 2.2.0
        def options
          {**connection_options, **adapter.gateway_options}
        end

        # @api private
        def configure_adapter(default_adapters)
          default_adapter = default_adapters[config.adapter_name]
          config.adapter ||= default_adapter.dup

          config.adapter.configure_from_adapter(default_adapter)
          config.adapter.configure_from_adapter(default_adapters[nil])
          config.adapter.configure_for_database(config.database_url)

          self
        end

        # @api private
        def cache_keys
          [config.database_url, config.connection_options, config.adapter.gateway_cache_keys]
        end

        private

        def method_missing(name, *args, &block)
          if config.respond_to?(name)
            config.public_send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, _include_all = false)
          config.respond_to?(name) || super
        end
      end
    end
  end
end
