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

        Controller.configure do
          action_module #{application_module}::Action
        end

        Controllers = Module.new unless defined?(#{application_module}::Controllers)

        unless defined?(#{application_module}::View)
          View = Lotus::View.generate(#{ application_module }) do
            root Utils::Kernel.Pathname("#{ configuration.root }/app/templates")
            layout :#{ configuration.layout }
          end
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
