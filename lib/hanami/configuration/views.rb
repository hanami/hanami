# frozen_string_literal: true

require "dry/configurable"
require "hanami/view"

module Hanami
  class Configuration
    # Hanami actions configuration
    #
    # @since 2.0.0
    class Views
      include Dry::Configurable

      setting :parts_path, default: "views/parts"

      attr_reader :base_configuration
      private :base_configuration

      def initialize(*)
        super

        @base_configuration = Hanami::View.config.dup

        configure_defaults
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        self.class.settings + View.settings - NON_FORWARDABLE_METHODS
      end

      def finalize!
        return self if frozen?

        base_configuration.finalize!

        super
      end

      private

      def configure_defaults
        self.paths = ["templates"]
        self.template_inference_base = "views"
        self.layout = "application"
      end

      # An inflector for views is not configurable via `config.views.inflector` on an
      # `Hanami::Application`. The application-wide inflector is already configurable
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
        elsif base_configuration.respond_to?(name)
          base_configuration.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_all = false)
        return false if NON_FORWARDABLE_METHODS.include?(name)

        config.respond_to?(name) || base_configuration.respond_to?(name) || super
      end
    end
  end
end
