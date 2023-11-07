# frozen_string_literal: true

require "dry/configurable"
require "hanami/view"

module Hanami
  class Config
    # Hanami views config
    #
    # This exposes all the settings from the standalone `Hanami::View` class, pre-configured with
    # sensible defaults for actions within a full Hanami app. It also provides additional settings
    # for further integration of views with other full stack app components.
    #
    # @since 2.1.0
    # @api public
    class Views
      include Dry::Configurable

      # @api private
      # @since 2.1.0
      attr_reader :base_config
      protected :base_config

      # @api private
      # @since 2.1.0
      def initialize(*)
        super

        @base_config = Hanami::View.config.dup

        configure_defaults
      end

      # @api private
      # @since 2.1.0
      def initialize_copy(source)
        super
        @base_config = source.base_config.dup
      end
      private :initialize_copy

      # @api private
      # @since 2.1.0
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
