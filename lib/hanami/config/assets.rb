# frozen_string_literal: true

require "dry/configurable"
require "hanami/assets"

module Hanami
  class Config
    # Hanami assets config
    #
    # This exposes all the settings from the standalone `Hanami::Assets` class, pre-configured with
    # sensible defaults for actions within a full Hanami app. It also provides additional settings
    # for further integration of assets with other full stack app components.
    #
    # @since 2.1.0
    # @api public
    class Assets
      include Dry::Configurable

      # @!attribute [rw] serve
      #   Serve static assets.
      #
      #   When this is `true`, the app will serve static assets.
      #
      #   If not set, this will:
      #
      #     * Check if the `HANAMI_SERVE_ASSETS` environment variable is set to `"true"`.
      #     * If not, it will check if the app is running in the `development` or `test` environment.
      #
      #   @example
      #     config.assets.serve = true
      #
      #   @return [Hanami::Config::Actions::Cookies]
      #
      #   @api public
      #   @since 2.1.0
      setting :serve

      # @api private
      attr_reader :base_config
      protected :base_config

      # @api private
      def initialize(*, **options)
        super()

        @base_config = Hanami::Assets::Config.new(**options)

        configure_defaults
      end

      # @api private
      def initialize_copy(source)
        super
        @base_config = source.base_config.dup
      end
      private :initialize_copy

      private

      def configure_defaults
        self.serve =
          if ENV.key?("HANAMI_SERVE_ASSETS")
            ENV["HANAMI_SERVE_ASSETS"] == "true"
          else
            Hanami.env?(:development, :test)
          end
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_config.respond_to?(name)
          base_config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_config.respond_to?(name) || super
      end
    end
  end
end
