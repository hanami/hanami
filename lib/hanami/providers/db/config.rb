# frozen_string_literal: true

require "dry/core"

module Hanami
  module Providers
    class DB < Hanami::Provider::Source
      # @api public
      # @since 2.2.0
      class Config < Dry::Configurable::Config
        include Dry::Core::Constants

        # @api public
        # @since 2.2.0
        def gateway(key)
          gateway = (gateways[key] ||= Gateway.new)
          yield gateway if block_given?
          gateway
        end

        # @api public
        # @since 2.2.0
        def adapter_name
          self[:adapter]
        end

        # @api public
        # @since 2.2.0
        def adapter(name = Undefined)
          return adapter_name if name.eql?(Undefined)

          adapter = (adapters[name] ||= Adapter.new)
          yield adapter if block_given?
          adapter
        end

        # @api public
        # @since 2.2.0
        def any_adapter
          adapter = (adapters[nil] ||= Adapter.new)
          yield adapter if block_given?
          adapter
        end

        # @api private
        def each_plugin
          return to_enum(__method__) unless block_given?

          universal_plugins = adapters[nil].plugins

          gateways.values.group_by(&:adapter_name).each do |adapter_name, adapter_gateways|
            per_adapter_plugins = adapter_gateways.map { _1.adapter.plugins }.flatten(1)

            (universal_plugins + per_adapter_plugins).uniq.each do |plugin_spec, config_block|
              yield adapter_name, plugin_spec, config_block
            end
          end
        end
      end
    end
  end
end
