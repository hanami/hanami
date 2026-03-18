# frozen_string_literal: true

module Hanami
  class Settings
    # A settings store that chains multiple stores with fallback resolution.
    #
    # Each store is tried in order. The first store to return a value wins.
    # Stores must implement `#fetch` with the same signature as `Hash#fetch`.
    #
    # @example
    #   # config/app.rb
    #   config.settings_store = Hanami::Settings::CompositeStore.new(
    #     Hanami::Settings::EnvStore.new,
    #     MyCustomStore.new
    #   )
    #
    # @api public
    # @since unreleased
    class CompositeStore
      # @api private
      NOT_SET = Object.new.freeze
      private_constant :NOT_SET

      # @param stores [Array<#fetch>] ordered list of stores to query
      def initialize(*stores)
        @stores = stores
      end

      # Fetches a value by trying each store in order.
      #
      # @param name [String, Symbol] the setting name
      # @param args [Array] optional default value
      # @yield [name] optional block for default value
      # @return [Object] the setting value
      # @raise [KeyError] if no store has the key and no default is given
      #
      # @api public
      # @since unreleased
      def fetch(name, *args, &block)
        @stores.each do |store|
          value = store.fetch(name, NOT_SET)
          return value unless value.equal?(NOT_SET)
        end

        return args.first unless args.empty?
        return yield(name) if block

        raise KeyError, "key not found: #{name.inspect}"
      end
    end
  end
end
