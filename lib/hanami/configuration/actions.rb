# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami configuration for actions
    #
    # @since 2.0.0
    class Actions
      attr_reader :configuration

      def initialize
        begin
          require "hanami/action/configuration"
          @configuration = Hanami::Action::Configuration.new
        rescue LoadError => e
          raise e unless e.path == "hanami/action/configuration"
          @configuration = nil
        end

        configure_defaults
      end

      private

      def configure_defaults
        return unless configuration

        self.default_request_format = DEFAULT_REQUEST_FORMAT
        self.default_response_format = DEFAULT_RESPONSE_FORMAT
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

      DEFAULT_REQUEST_FORMAT = :html
      private_constant :DEFAULT_REQUEST_FORMAT

      DEFAULT_RESPONSE_FORMAT = :html
      private_constant :DEFAULT_RESPONSE_FORMAT
    end
  end
end
