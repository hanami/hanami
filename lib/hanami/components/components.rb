module Hanami
  # Registered components
  #
  # @since x.x.x
  # @api private
  #
  # @see Hanami::Components
  module Components # rubocop:disable Metrics/ModuleLength
    # Require the entire project
    #
    # @since x.x.x
    # @api private
    register 'all' do
      requires 'model', 'apps'

      resolve { true }
    end

    # Tries to load hanami-model, if available for the project
    #
    # @since x.x.x
    # @api private
    #
    # @example With hanami-model
    #   Hanami::Components.resolve('model')
    #   Hanami::Components['model'] # => true
    #
    # @example Without hanami-model
    #   Hanami::Components.resolve('model')
    #   Hanami::Components['model'] # => nil
    register 'model' do
      requires 'model.configuration'

      resolve do
        if defined?(Hanami::Model)
          Hanami::Model.load!
          true
        end
      end
    end

    # Tries to evaluate hanami-model configuration, if available for the project
    #
    # @since x.x.x
    # @api private
    #
    # @example With hanami-model
    #   Hanami::Components.resolve('model.configuration')
    #   Hanami::Components['model.configuration'].class # => Hanami::Model::Configuration
    #
    # @example Without hanami-model
    #   Hanami::Components.resolve('model.configuration')
    #   Hanami::Components['model.configuration'].class # => NilClass
    register 'model.configuration' do
      prepare do
        begin
          require 'hanami/model'
        rescue LoadError # rubocop:disable Lint/HandleExceptions
        end
      end

      resolve do |configuration|
        if defined?(Hanami::Model)
          Hanami::Model.configure(&configuration.model)
          Hanami::Model.configuration
        end
      end
    end

    # Loads the routes for all the mounted Hanami/Rack applications
    #
    # This is used only by `hanami routes` command.
    #
    # @since x.x.x
    # @api private
    register 'routes.inspector' do
      requires 'apps.configurations'

      prepare do
        require 'hanami/components/routes_inspector'
      end

      resolve do |configuration|
        RoutesInspector.new(configuration)
      end
    end

    # Loads all the Hanami applications in the project
    #
    # @since x.x.x
    # @api private
    register 'apps' do
      run do |configuration|
        configuration.apps do |app|
          component('app').call(app)
        end
      end
    end

    # Evaluates all the Hanami applications' configurations in the project
    #
    # @since x.x.x
    # @api private
    register 'apps.configurations' do
      resolve do |configuration|
        configuration.apps do |app|
          component('app.configuration').call(app)
        end

        true
      end
    end

    # Evaluates all the Hanami assets configurations for each application in the project
    #
    # This is used only by `hanami assets precompile` command.
    #
    # @since x.x.x
    # @api private
    register 'apps.assets.configurations' do
      requires 'apps.configurations'

      prepare do
        require 'hanami/components/app/assets'
      end

      resolve do |configuration|
        [].tap do |result|
          configuration.apps do |app|
            result << Components::App::Assets.resolve(app)
          end
        end
      end
    end

    # Configure, load and finalize a Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app' do
      run do |app|
        ['app.configuration', 'app.frameworks', 'app.code', 'app.routes', 'app.finalizer'].each do |c|
          component(c).call(app)
        end

        resolved(app.app_name, true)
      end
    end

    # Evaluate the configuration of a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.configuration' do
      run do |app|
        resolved("#{app.app_name}.configuration") do
          ApplicationConfiguration.new(app.namespace, app.configurations, app.path_prefix).tap do |config|
            app.configuration = config
          end
        end
      end
    end

    # Evaluate Hanami frameworks configurations of a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.frameworks' do
      run do |app|
        ['app.controller', 'app.view', 'app.assets', 'app.logger'].each do |c|
          component(c).call(app)
        end
      end
    end

    # Evaluate hanami-controller configuration of a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.controller' do
      prepare do
        require 'hanami/components/app/controller'
      end

      run do |app|
        Components::App::Controller.resolve(app)
      end
    end

    # Evaluate hanami-view configuration of a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.view' do
      prepare do
        require 'hanami/components/app/view'
      end

      run do |app|
        Components::App::View.resolve(app)
      end
    end

    # Evaluate hanami-assets configuration of a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.assets' do
      prepare do
        require 'hanami/components/app/assets'
      end

      run do |app|
        Components::App::Assets.resolve(app)
      end
    end

    # Evaluate hanami/logger configuration of a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.logger' do
      prepare do
        require 'hanami/components/app/logger'
      end

      run do |app|
        Components::App::Logger.resolve(app)
      end
    end

    # Load the code for a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.code' do
      run do |app|
        config = app.configuration
        config.load_paths.load!
      end
    end

    # Load the routes for a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.routes' do
      prepare do
        require 'hanami/components/app/routes'
      end

      run do |app|
        Components::App::Routes.resolve(app)
      end
    end

    # Finalize a single Hanami application in the project
    #
    # @since x.x.x
    # @api private
    register 'app.finalizer' do
      run do |app|
        config    = app.configuration
        namespace = app.namespace

        config.middleware.load!

        namespace.module_eval %(#{namespace}::Controller.load!)
        namespace.module_eval %(#{namespace}::View.load!)
        namespace.module_eval %(#{namespace}::Assets.load!)
      end
    end
  end
end
