# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Configuration
    # Hanami configuration for views
    #
    # @since 2.0.0
    class Views
      attr_reader :configuration

      def initialize
        begin
          require "hanami/view"
          @configuration = Hanami::View.config.dup
        rescue LoadError => e
          raise e unless e.path == "hanami/view"
          @configuration = nil
        end

        configure_defaults
      end

      private

      def configure_defaults
        return unless configuration

        self.paths = ["web/templates"]
        self.template_inference_base = "views"
        self.layout = "application"
      end

      def method_missing(name, *args, &block)
        if configuration&.respond_to?(name)
          configuration.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_private = false)
        configuration&.respond_to?(name) || super
      end
    end
  end
end
