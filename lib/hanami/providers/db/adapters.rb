# frozen_string_literal: true

module Hanami
  module Providers
    class DB < Hanami::Provider::Source
      # @api public
      # @since 2.2.0
      class Adapters
        # @api private
        # @since 2.2.0
        ADAPTER_CLASSES = Hash.new(Adapter).update(
          sql: SQLAdapter
        ).freeze
        private_constant :ADAPTER_CLASSES

        extend Forwardable

        def_delegators :adapters, :[], :[]=, :each, :to_h

        # @api private
        # @since 2.2.0
        def self.new_adapter(name)
          ADAPTER_CLASSES[name].new
        end

        # @api private
        # @since 2.2.0
        attr_reader :adapters

        # @api private
        # @since 2.2.0
        def initialize
          @adapters = {}
        end

        # @api private
        # @since 2.2.0
        def initialize_copy(source)
          @adapters = source.adapters.dup

          source.adapters.each do |key, val|
            @adapters[key] = val.dup
          end
        end

        # @api private
        # @since 2.2.0
        def adapter(key)
          adapters[key] ||= new(key)
        end

        # @api private
        # @since 2.2.0
        def find(key)
          adapters.fetch(key) { new(key) }
        end

        # @api private
        # @since 2.2.0
        def new(key)
          self.class.new_adapter(key)
        end
      end
    end
  end
end
