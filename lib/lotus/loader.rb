require 'lotus/utils/class'
require 'lotus/utils/kernel'
require 'lotus/utils/string'
require 'lotus/routes'
require 'lotus/routing/default'
require 'lotus/action/cookies'

module Lotus
  # Load an application
  #
  # @since 0.1.0
  # @api private
  class Loader
    def initialize(application)
      @application   = application
      @configuration = @application.configuration

      @mutex = Mutex.new
    end

    def load!
      @mutex.synchronize do
        load_configuration!
        load_frameworks!
        load_configuration_load_paths!
        load_rack!
        finalize!
      end
    end

    private
    attr_reader :application, :configuration

    def load_configuration!
      configuration.load!(application_module)
    end

    def load_frameworks!
      _load_controller_framework!
      _load_view_framework!
    end

    def _load_controller_framework!
      config = configuration
      unless application_module.const_defined?('Controller')
        controller = Lotus::Controller.duplicate(application_module) do
          handle_exceptions config.handle_exceptions
          default_format    config.default_format

          modules { include Lotus::Action::Cookies } if config.cookies
        end

        application_module.const_set('Controller', controller)
      end
    end

    def _load_view_framework!
      config = configuration
      unless application_module.const_defined?('View')
        view = Lotus::View.duplicate(application_module) do
          root   config.templates
          layout config.layout
        end

        application_module.const_set('View', view)
      end
    end

    def finalize!
      application_module.module_eval %{
        #{ application_module }::View.load!
      }
    end

    def load_configuration_load_paths!
      configuration.load_paths.load!(configuration.root)
    end

    def load_rack!
      return if application.is_a?(Class)
      _assign_rack_routes!
      _load_rack_middleware!
      _assign_routes_to_application_module!
    end

    def _assign_rack_routes!
      namespace = configuration.namespace || application_module
      resolver    = Lotus::Routing::EndpointResolver.new(pattern: configuration.controller_pattern, namespace: namespace)
      default_app = Lotus::Routing::Default.new
      application.routes = Lotus::Router.new(
        resolver:    resolver,
        default_app: default_app,
        scheme:      configuration.scheme,
        host:        configuration.host,
        port:        configuration.port,
        &configuration.routes
      )
    end

    def _load_rack_middleware!
      namespace = configuration.namespace || application_module
      configuration.middleware.load!(application, namespace)
    end

    def _assign_routes_to_application_module!
      unless application_module.const_defined?('Routes')
        routes = Lotus::Routes.new(application.routes)
        application_module.const_set('Routes', routes)
      end
    end

    def application_module
      @application_module ||= Utils::Class.load!(
        Utils::String.new(application.name).namespace
      )
    end
  end
end
