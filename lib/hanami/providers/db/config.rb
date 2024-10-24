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
        def adapter(name)
          adapter = adapters.adapter(name)
          yield adapter if block_given?
          adapter
        end

        # @api private
        def each_plugin
          return to_enum(__method__) unless block_given?

          gateways.values.group_by(&:adapter_name).each do |adapter_name, adapter_gateways|
            per_adapter_plugins = adapter_gateways.map { _1.adapter.plugins }.flatten(1).uniq

            per_adapter_plugins.each do |plugin_spec, config_block|
              yield adapter_name, plugin_spec, config_block
            end
          end
        end
      end
    end
  end
end
