require 'lotus/utils/class'
require 'lotus/utils/kernel'
require 'lotus/utils/string'
require 'lotus/routes'
require 'lotus/routing/default'

module Lotus
  class Loader
    def initialize(application)
      @application   = application
      @configuration = @application.configuration

      @mutex = Mutex.new
    end

    def load!
      @mutex.synchronize do
        load_frameworks!
        load_application!
        finalize!
      end
    end

    private
    attr_reader :application, :configuration

    def load_frameworks!
      # TODO try to avoid module_eval %{}
      application_module.module_eval %{
        unless defined?(#{application_module}::Controller)
          Controller = Lotus::Controller.generate(#{ application_module })
        end

        unless defined?(#{application_module}::View)
          View = Lotus::View.generate(#{ application_module }) do
            root Utils::Kernel.Pathname("#{ configuration.root }/app/templates")
            layout "#{ configuration.layout }".to_sym unless #{ configuration.layout.nil? }
          end
        end
      }
    end

    def load_application!
      configuration.load_paths.load!

      resolver    = Lotus::Routing::EndpointResolver.new(pattern: configuration.controller_pattern, namespace: application_module)
      default_app = Lotus::Routing::Default.new
      application.routes = Lotus::Router.new(
        resolver:    resolver,
        default_app: default_app,
        scheme:      configuration.scheme,
        host:        configuration.host,
        port:        configuration.port,
        &configuration.routes
      )

      application.middleware # preload
    end

    def finalize!
      # TODO try to avoid module_eval %{}
      routes = Lotus::Routes.new(application.routes)

      application_module.module_eval %{
        unless defined?(#{application_module}::Routes)
          Routes = routes
        end

        View.load!
      }
    end

    def application_module
      @application_module ||= Utils::Class.load!(
        Utils::String.new(application.class).namespace
      )
    end
  end
end
