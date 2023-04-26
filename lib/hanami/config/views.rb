# frozen_string_literal: true

require "dry/configurable"
require "hanami/view"

module Hanami
  class Config
    # Hanami views config
    #
    # This is NOT RELEASED as of 2.0.0.
    #
    # @api private
    class Views
      include Dry::Configurable

      attr_reader :base_config
      protected :base_config

      # @api private
      def initialize(*)
        super

        @base_config = Hanami::View.config.dup

        configure_defaults
      end

      # @api private
      def initialize_copy(source)
        super
        @base_config = source.base_config.dup
      end
      private :initialize_copy

      # @api private
      def finalize!
        return self if frozen?

        base_config.finalize!

        super
      end

      private

      def configure_defaults
        self.layout = "app"
      end

      # An inflector for views is not configurable via `config.views.inflector` on an
      # `Hanami::App`. The app-wide inflector is already configurable
      # there as `config.inflector` and will be used as the default inflector for views.
      #
      # A custom inflector may still be provided in an `Hanami::View` subclass, via
      # `config.inflector=`.
      NON_FORWARDABLE_METHODS = %i[inflector inflector=].freeze
      private_constant :NON_FORWARDABLE_METHODS

      def method_missing(name, *args, &block)
        return super if NON_FORWARDABLE_METHODS.include?(name)

        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_config.respond_to?(name)
          base_config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_all = false)
        return false if NON_FORWARDABLE_METHODS.include?(name)

        config.respond_to?(name) || base_config.respond_to?(name) || super
      end
    end
  end
end
