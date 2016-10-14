require 'hanami/routing/default'

module Hanami
  module Components
    class RoutesInspector
      # @param configuration [Hanami::Configuration]
      #
      # @since x.x.x
      # @api private
      def initialize(configuration)
        @configuration = configuration
      end

      def inspect
        routes.map do |r|
          r.inspector.to_s
        end.join("\n")
      end

      private

      attr_reader :configuration

      def routes
        configuration.mounted.each_with_object([]) do |(klass, app), result|
          result << if hanami_app?(klass)
                      resolve_hanami_app_router(app)
                    else
                      resolve_rack_app_router(app)
                    end
        end
      end

      def hanami_app?(klass)
        klass.ancestors.include?(Hanami::Application)
      end

      def resolve_hanami_app_router(app)
        config = Components["#{app.app_name}.configuration"]

        resolver    = Hanami::Routing::EndpointResolver.new(pattern: config.controller_pattern, namespace: config.namespace)
        default_app = Hanami::Routing::Default.new

        Hanami::Router.new(
          resolver:    resolver,
          default_app: default_app,
          prefix:      app.path_prefix,
          parsers:     config.body_parsers,
          scheme:      config.scheme,
          host:        config.host,
          port:        config.port,
          force_ssl:   config.force_ssl,
          &config.routes
        )
      end

      def resolve_rack_app_router(app)
        Hanami::Router.new do
          mount app.name, at: app.path_prefix
        end
      end
    end
  end
end
