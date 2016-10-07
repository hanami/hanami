require 'concurrent'
require 'hanami/component'

module Hanami
  # Components
  #
  # @since x.x.x
  module Components
    # FIXME: review if this is the right data structure for @_components
    @_components = Concurrent::Hash.new
    @_resolved   = Concurrent::Map.new

    def self.register(name, component)
      @_components[name] = component
    end

    def self.resolved(name, value)
      @_resolved.merge_pair(name, value)
    end

    def self.resolve(names)
      names.each do |name|
        @_resolved.fetch_or_store(name) do
          component = @_components.fetch(name)
          component.new(Hanami.configuration).resolve
        end
      end
    end

    def self.[](name)
      @_resolved.fetch(name) do
        raise ArgumentError.new("Component not found: `#{name}'.\nAvailable components are: #{@_resolved.keys.join(', ')}")
      end
    end

    # Catch all for components
    #
    # @since x.x.x
    class All < Component
      register_as 'all'
      requires 'model'

      def resolve
        Hanami.boot
        true
      end
    end

    # Configurations for all the apps
    #
    # @since x.x.x
    class Apps < Component
      requires 'apps.configurations', 'apps.frameworks.configuration', 'apps.code'

      def resolve
        configuration.apps do |app, path_prefix|
          # load_rack
          # load frameworks
        end

        true
      end
    end

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

    # Model
    #
    # @since x.x.x
    class Model < Component
      register_as 'model'
      requires 'model.configuration'

      def resolve
        if defined?(Hanami::Model)
          Hanami::Model.load!
          true
        else
          false
        end
      end
    end

    # Model configuration
    #
    # @since x.x.x
    class ModelConfiguration < Component
      register_as 'model.configuration'

      def resolve
        require 'hanami/model'

        Hanami::Model.configure(&configuration.model)
        Hanami::Model.configuration
      rescue LoadError # rubocop:disable Lint/HandleExceptions
      end
    end

    # Configurations for all the apps
    #
    # @since x.x.x
    class AppsConfigurations < Component
      register_as 'apps.configurations'

      def resolve
        configuration.apps do |app, path_prefix|
          config = app.configuration
          config.path_prefix path_prefix
          config.load!(app.app_name) # FIXME: remove app_name as argument

          Components.resolved("#{app.app_name}.configuration", config)
        end

        true
      end
    end

    # Configurations for all the apps
    #
    # @since x.x.x
    class AppsAssetsConfigurations < Component
      register_as 'apps.assets.configurations'
      requires    'apps.configurations'

      def resolve
        result = []

        configuration.apps do |app, _|
          config = configuration_for(app)

          assets = Hanami::Assets::Configuration.new do
            root             config.root

            scheme           config.scheme
            host             config.host
            port             config.port

            public_directory Hanami.public_directory
            prefix           Utils::PathPrefix.new('/assets').join(config.path_prefix)

            manifest         Hanami.public_directory.join('assets.json')
            compile          true

            config.assets.__apply(self)
            cdn host != config.host
          end

          Components.resolved("#{app.app_name}.assets.configuration", assets)
          assets.load!

          result << assets
        end

        result
      end

      private

      def configuration_for(app)
        requirements["#{app.app_name}.configuration"]
      end
    end
  end
end
