module Hanami
  module Components
    module App
      class Routes
        def self.resolve(app)
          config    = app.configuration
          namespace = app.namespace

          unless namespace.const_defined?('Routes', false)
            routes = Hanami::Routes.new(application_routes(config, namespace))
            namespace.const_set('Routes', routes)
          end
        end

        def self.application_routes(config, namespace)
          resolver    = Hanami::Routing::EndpointResolver.new(pattern: config.controller_pattern, namespace: namespace)
          default_app = Hanami::Routing::Default.new

          Hanami::Router.new(
            resolver:    resolver,
            default_app: default_app,
            parsers:     config.body_parsers,
            scheme:      config.scheme,
            host:        config.host,
            port:        config.port,
            prefix:      config.path_prefix,
            force_ssl:   config.force_ssl,
            &config.routes
          )
        end
      end
    end
  end
end
