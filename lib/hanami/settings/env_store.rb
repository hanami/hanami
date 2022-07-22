# frozen_string_literal: true

require "dry/core/constants"

module Hanami
  class Settings
    # The default store for {Hanami:Settings}, loading setting values from `ENV`.
    #
    # If your app loads the dotenv gem, then `ENV` will also be populated from various `.env` files when
    # you subclass `Hanami::App`.
    #
    # @since 2.0.0
    # @api private
    class EnvStore
      Undefined = Dry::Core::Constants::Undefined

      attr_reader :store, :hanami_env

      def initialize(store: ENV, hanami_env: Hanami.env)
        @store = store
        @hanami_env = hanami_env
      end

      def fetch(name, default_value = Undefined, &block)
        name = name.to_s.upcase
        args = default_value == Undefined ? [name] : [name, default_value]

        store.fetch(*args, &block)
      end
    end
  end
end
