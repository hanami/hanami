require 'hanami/utils/class'
require 'hanami/utils/kernel'
require 'hanami/utils/string'
require 'hanami/routes'
require 'hanami/routing/default'
require 'hanami/action/session'
require 'hanami/config/security'
require 'hanami/action/routing_helpers'

module Hanami
  # Load an application
  #
  # @since 0.1.0
  # @api private
  class Loader

    STRICT_TRANSPORT_SECURITY_HEADER = 'Strict-Transport-Security'.freeze
    STRICT_TRANSPORT_SECURITY_DEFAULT_VALUE = 'max-age=31536000'.freeze

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
        load_initializers!
      end
    end

    private
    attr_reader :application, :configuration

    def load_configuration!
      configuration.load!(application_module)
    end

    def configure_frameworks!
      _configure_model_framework! if defined?(Hanami::Model)
      _configure_controller_framework!
      _configure_view_framework!
      _configure_assets_framework!
      _configure_logger!
    end

    def _configure_controller_framework!
      config = configuration
      unless namespace.const_defined?('Controller')
        controller = Hanami::Controller.duplicate(namespace) do
          handle_exceptions config.handle_exceptions
          default_request_format config.default_request_format
          default_response_format config.default_response_format
          default_headers({
            Hanami::Config::Security::X_FRAME_OPTIONS_HEADER         => config.security.x_frame_options,
            Hanami::Config::Security::CONTENT_SECURITY_POLICY_HEADER => config.security.content_security_policy,
          })
          default_headers.merge!(STRICT_TRANSPORT_SECURITY_HEADER => STRICT_TRANSPORT_SECURITY_DEFAULT_VALUE) if config.force_ssl

          if config.cookies.enabled?
            require 'hanami/action/cookies'
            prepare { include Hanami::Action::Cookies }
            cookies config.cookies.default_options
          end

          if config.sessions.enabled?
            prepare do
              include Hanami::Action::Session
              include Hanami::Action::CSRFProtection
            end
          end

          prepare { include Hanami::Action::RoutingHelpers }

          config.controller.__apply(self)
        end

        namespace.const_set('Controller', controller)
      end
    end

    def _configure_view_framework!
      config = configuration
      unless namespace.const_defined?('View')
        view = Hanami::View.duplicate(namespace) do
          root   config.templates
          layout config.layout

          config.view.__apply(self)
        end

        namespace.const_set('View', view)
      end
    end

    def _configure_assets_framework!
      config = configuration

      unless application_module.const_defined?('Assets')
        assets = Hanami::Assets.duplicate(namespace) do
          root             config.root

          scheme           config.scheme
          host             config.host
          port             config.port

          public_directory Hanami.public_directory
          prefix           Utils::PathPrefix.new('/assets').join(config.path_prefix)

          manifest         Hanami.public_directory.join('assets.json')
          compile          true

          config.assets.__apply(self)
        end

        assets.configure do
          cdn host != config.host
        end

        application_module.const_set('Assets', assets)
      end
    end

    def _configure_model_framework!
      config = configuration
      if _hanami_model_loaded? && !application_module.const_defined?('Model')
        model = Hanami::Model.duplicate(application_module) do
          adapter(config.adapter)  if config.adapter
          mapping(&config.mapping) if config.mapping

          config.model.__apply(self)
        end

        application_module.const_set('Model', model)
      end
    end

    def _configure_logger!
      unless application_module.const_defined?('Logger', false)
        configuration.logger.app_name(application_module.to_s)
        application_module.const_set('Logger', configuration.logger.build)
      end
    end

    def load_frameworks!
      _load_view_framework!
      _load_assets_framework!
      _load_model_framework!
    end

    def _load_view_framework!
      namespace.module_eval %{
        #{ namespace }::View.load!
      }
    end

    def _load_assets_framework!
      application_module.module_eval %{
        #{ application_module }::Assets.load!
      }
    end

    def _load_model_framework!
      return unless _load_model_framework?

      application_module.module_eval %{
        #{ application_module }::Model.load!
      }
    end

    def _load_model_framework?
      if _hanami_model_loaded? && application_module.const_defined?('Model')
        model = application_module.const_get('Model')
        model.configuration.adapter
      end
    end

    def _hanami_model_loaded?
      defined?(Hanami::Model)
    end

    def _hanami_mailer_loaded?
      defined?(Hanami::Mailer)
    end

    def load_configuration_load_paths!
      configuration.load_paths.load!(configuration.root)
    end

    def load_rack!
      _assign_routes_to_application_module!

      return if application.is_a?(Class)
      _assign_rendering_policy!
      _assign_rack_routes!
      _load_rack_middleware!
    end

    def _assign_rendering_policy!
      application.renderer = RenderingPolicy.new(configuration)
    end

    def _assign_rack_routes!
      application.routes = application_routes
    end

    def _load_rack_middleware!
      configuration.middleware.load!(application, namespace)
    end

    def _assign_routes_to_application_module!
      unless application_module.const_defined?('Routes')
        routes = Hanami::Routes.new(application_routes)
        application_module.const_set('Routes', routes)
      end
    end

    def application_module
      @application_module ||= Utils::Class.load!(
        Utils::String.new(application.name).namespace
      )
    end

    def application_routes
      resolver    = Hanami::Routing::EndpointResolver.new(pattern: configuration.controller_pattern, namespace: namespace)
      default_app = Hanami::Routing::Default.new
      Hanami::Router.new(
        parsers:     configuration.body_parsers,
        resolver:    resolver,
        default_app: default_app,
        scheme:      configuration.scheme,
        host:        configuration.host,
        port:        configuration.port,
        prefix:      configuration.path_prefix,
        force_ssl:   configuration.force_ssl,
        &configuration.routes
      )
    end

    def namespace
      configuration.namespace || application_module
    end

    def load_initializers!
      Dir["#{configuration.root}/config/initializers/**/*.rb"].each do |file|
        require file
      end
    end
  end
end
