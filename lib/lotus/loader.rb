require 'lotus/utils/kernel'
require 'lotus/utils/string'

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
      application_module.module_eval %{
        Controller = Lotus::Controller.duplicate unless defined?(#{application_module}::Controller)
        Action     = Lotus::Action.dup           unless defined?(#{application_module}::Action)
        View       = Lotus::View.duplicate       unless defined?(#{application_module}::View)

        Controller.configure do
          action_module #{application_module}::Action
        end

        Controllers = Module.new unless defined?(#{application_module}::Controllers)
        Views       = Module.new unless defined?(#{application_module}::Views)

        View.configure do
          root Utils::Kernel.Pathname("#{ configuration.root }/app/templates")
          namespace #{application_module}::Views
          layout :#{ configuration.layout } # THIS should work because of the lazy loading
        end
      }
    end

    def load_application!
      configuration.load_paths.load!

      resolver = Lotus::Routing::EndpointResolver.new(pattern: configuration.controller_pattern, namespace: application_module)
      application.routes = Lotus::Router.new(resolver: resolver, &configuration.routes)

      # FIXME assign mapping only if Lotus::Model is defined
      application.mapping = Lotus::Model::Mapper.new(&configuration.mapping)
    end

    def finalize!
      application_module.module_eval %{
        if #{ !configuration.layout.nil? }
          View.configure do
            layout :#{ configuration.layout }
          end
        end

        View.load!
      }

      # FIXME load mapping only if Lotus::Model is defined
      application.mapping.load!
    end

    def application_module
      # TODO refactor in favor of Utils::Class
      Object.const_get application.class.name.split('::').first
    end
  end
end
