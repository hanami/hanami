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
          yield adapter  if block_given?
          adapter
        end

        # @api private
        # @since 2.2.0
        def gateway_cache_keys
          adapters[adapter_name].gateway_cache_keys
        end

        # @api private
        # @since 2.2.0
        def gateway_options
          adapters[adapter_name].gateway_options
        end

        # @api public
        # @since 2.2.0
        def each_plugin
          universal_plugins = adapters[nil].plugins
          adapter_plugins = adapters[adapter_name].plugins

          plugins = universal_plugins + adapter_plugins

          return to_enum(__method__) unless block_given?

          plugins.each do |plugin_spec, config_block|
            yield plugin_spec, config_block
          end
        end
      end
    end
  end
end
