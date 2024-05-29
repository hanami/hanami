# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Config
    # Hanami DB config
    #
    # @since 2.2.0
    # @api public
    class DB
      include Dry::Configurable

      setting :configure_from_parent, default: true

      setting :import_from_parent, default: false

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
