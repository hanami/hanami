# frozen_string_literal: true

require "dry/core/constants"

module Hanami
  class Settings
    # A settings store that loads setting values from `ENV`, with each setting name upcased.
    #
    # This is the first store in the default settings store, ahead of the YAML settings files.
    #
    # If your app loads the dotenv gem, then `ENV` will also be populated from various `.env` files when
    # you subclass `Hanami::App`.
    #
    # @example
    #   # config/app.rb
    #   config.settings_store = Hanami::Settings::CompositeStore.new(
    #     Hanami::Settings::EnvStore.new,
    #     MyCustomStore.new
    #   )
    #
    # @api public
    # @since 2.0.0
    class EnvStore
      # @api private
      NO_ARG = Object.new.freeze

      # @api private
      attr_reader :store, :hanami_env

      # Returns a new instance of the store.
      #
      # @param store [#fetch] the store to load values from
      # @param hanami_env [Symbol] the Hanami env
      #
      # @api public
      # @since 2.0.0
      def initialize(store: ENV, hanami_env: Hanami.env)
        @store = store
        @hanami_env = hanami_env
      end

      # Fetches a value by its upcased name, such as `DATABASE_URL` for `:database_url`.
      #
      # @param name [String, Symbol] the setting name
      # @param default_value [Object] optional default value
      # @yield [name] optional block for default value
      # @return [Object] the setting value
      # @raise [KeyError] if `ENV` has no value for the name and no default is given
      #
      # @api public
      # @since 2.0.0
      def fetch(name, default_value = NO_ARG, &block)
        name = name.to_s.upcase
        args = default_value.eql?(NO_ARG) ? [name] : [name, default_value]

        store.fetch(*args, &block)
      end
    end
  end
end
