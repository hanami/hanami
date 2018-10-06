require 'hanami/routes'
require 'hanami/routing/default'

module Hanami
  # @since 0.9.0
  # @api private
  module Components
    # @since 0.9.0
    # @api private
    module App
      # hanami-router configuration for a sigle Hanami application in the project.
      #
      # @since 0.9.0
      # @api private
      class Routes
        # Configure hanami-router for a single Hanami application in the project.
        #
        # @param app [Hanami::Configuration::App] a Hanami application
        #
        # @since 0.9.0
        # @api private
        def self.resolve(app)
          namespace = app.namespace
          routes    = application_routes(app)

          if namespace.routes.nil? # rubocop:disable Style/IfUnlessModifier
            namespace.routes = Hanami::Routes.new(routes)
          end

          Components.resolved("#{app.app_name}.routes", routes)
        end

        # @since 0.9.0
        # @api private
        def self.application_routes(app) # rubocop:disable Metrics/MethodLength
          config      = app.configuration
          namespace   = app.namespace

          resolver    = Hanami::Routing::EndpointResolver.new(pattern: config.controller_pattern, namespace: namespace)
          default_app = Hanami::Routing::Default.new

          options = {
            resolver:    resolver,
            default_app: default_app,
            scheme:      config.scheme,
            host:        config.host,
            port:        config.port,
            prefix:      config.path_prefix,
            force_ssl:   config.force_ssl
          }

          options[:parsers] = config.body_parsers if config.body_parsers.any?

          Hanami::Router.new(options, &config.routes)
        end
      end
    end
  end
end
