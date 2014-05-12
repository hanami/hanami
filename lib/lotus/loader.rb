require 'lotus/utils/kernel'

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
      # FIXME only add that exception if Lotus::Model is defined
      # FIXME read the layout from the configuration
      # FIXME layout class must be nested into CoffeeShop
      application_module.module_eval %{
        Controller = Lotus::Controller.dup unless defined?(#{application_module}::Controller)
        View       = Lotus::View.dup       unless defined?(#{application_module}::View)

        Controller.handled_exceptions = { Lotus::Model::EntityNotFound => 404 }
        View.root                     = Utils::Kernel.Pathname("#{ configuration.root }")
        View.layout                   = :application
      }
    end

    def load_application!
      configuration.loading_paths.load!

      # FIXME assign mapping only if Lotus::Model is defined
      application.routes  = Lotus::Router.new(&configuration.routes)
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
