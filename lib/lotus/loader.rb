require 'lotus/utils/class'
require 'lotus/utils/kernel'
require 'lotus/utils/string'
require 'lotus/routes'
require 'lotus/routing/default'
require 'lotus/action/cookies'
require 'lotus/action/session'

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
        configure_frameworks!
        load_configuration_load_paths!
        load_rack!
        load_frameworks!
      end
    end

    private
    attr_reader :application, :configuration

    def load_configuration!
      configuration.load!(application_module)
    end

    def configure_frameworks!
      _configure_model_framework! if defined?(Lotus::Model)
      _configure_controller_framework!
      _configure_view_framework!
    end

    def _configure_controller_framework!
      config = configuration
      unless application_module.const_defined?('Controller')
        controller = Lotus::Controller.duplicate(application_module) do
          handle_exceptions config.handle_exceptions
          default_format    config.default_format

          prepare { include Lotus::Action::Cookies } if config.cookies
          prepare { include Lotus::Action::Session } if config.sessions.enabled?

          config.controller.__apply(self)
        end

        application_module.const_set('Controller', controller)
      end
    end

    def _configure_view_framework!
      config = configuration
      unless application_module.const_defined?('View')
        view = Lotus::View.duplicate(application_module) do
          root   config.templates
          layout config.layout

          config.view.__apply(self)
        end

        application_module.const_set('View', view)
      end
    end

    def _configure_model_framework!
      config = configuration
      if _lotus_model_loaded? && !application_module.const_defined?('Model')
        model = Lotus::Model.duplicate(application_module) do
          adapter(config.adapter)  if config.adapter
          mapping(&config.mapping) if config.mapping

          config.model.__apply(self)
        end

        application_module.const_set('Model', model)
      end
    end


    def load_frameworks!
      _load_view_framework!
      _load_model_framework!
    end

    def _load_view_framework!
      application_module.module_eval %{
        #{ application_module }::View.load!
      }
    end

    def _load_model_framework!
      return unless _load_model_framework?

      application_module.module_eval %{
        #{ application_module }::Model.load!
      }
    end

    def _load_model_framework?
      if _lotus_model_loaded? && application_module.const_defined?('Model')
        model = application_module.const_get('Model')
        model.configuration.adapter
      end
    end

    def _lotus_model_loaded?
      defined?(Lotus::Model)
    end

    def load_configuration_load_paths!
      configuration.load_paths.load!(configuration.root)
    end

    def load_rack!
      return if application.is_a?(Class)
      _assign_rendering_policy!
      _assign_rack_routes!
      _load_rack_middleware!
      _assign_routes_to_application_module!
    end

    def _assign_rendering_policy!
      application.renderer = RenderingPolicy.new(configuration)
    end

    def _assign_rack_routes!
      namespace = configuration.namespace || application_module
      resolver    = Lotus::Routing::EndpointResolver.new(pattern: configuration.controller_pattern, namespace: namespace)
      default_app = Lotus::Routing::Default.new
      application.routes = Lotus::Router.new(
        parsers:     configuration.body_parsers,
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
