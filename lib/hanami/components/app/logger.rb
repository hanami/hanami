require 'hanami/logger'

module Hanami
  module Components
    module App
      # hanami/logger configuration for a sigle Hanami application in the project.
      #
      # @since 0.9.0
      # @api private
      class Logger
        # Configure hanami/logger for a single Hanami application in the project.
        #
        # @param app [Hanami::Configuration::App] a Hanami application
        #
        # @since 0.9.0
        # @api private
        def self.resolve(app)
          namespace = app.namespace
          return unless namespace.logger.nil?

          config = app.configuration

          # TODO: review this logic
          config.logger.app_name(namespace.to_s)
          namespace.logger = config.logger.build
        end
      end
    end
  end
end
