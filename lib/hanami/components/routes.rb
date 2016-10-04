require 'hanami/router'
require 'hanami/application'

module Hanami
  module Components
    # Project routes
    #
    # @since x.x.x
    class Routes < Component
      register_as 'routes'
      requires    'apps.configurations'

      class RoutesSet
        def initialize(routes)
          @routes = routes
        end

        def inspect
          @routes.map do |r|
            r.inspector.to_s
          end.join("\n")
        end
      end

      def resolve
        RoutesSet.new(routes)
      end

      private

      def routes
        configuration.mounted.each_with_object([]) do |(app, path_prefix), result|
          result << if hanami_app?(app)
                      resolve_hanami_app_router(app, path_prefix)
                    else
                      resolve_rack_app_router(app, path_prefix)
                    end
        end
      end

      def hanami_app?(app)
        app.ancestors.include?(Hanami::Application)
      end

      def resolve_hanami_app_router(app, path_prefix)
        config = requirements["#{app.app_name}.configuration"]

        resolver    = Hanami::Routing::EndpointResolver.new(pattern: config.controller_pattern, namespace: config.namespace)
        default_app = Hanami::Routing::Default.new

        Hanami::Router.new(
          prefix:      path_prefix,
          resolver:    resolver,
          default_app: default_app,
          parsers:     config.body_parsers,
          scheme:      config.scheme,
          host:        config.host,
          port:        config.port,
          force_ssl:   config.force_ssl,
          &config.routes
        )
      end

      def resolve_rack_app_router(app, path_prefix)
        Hanami::Router.new do
          mount app.name, at: path_prefix
        end
      end
    end
  end
end
