require 'hanami/utils'

module Hanami
  # Registered components
  #
  # @since 0.9.0
  # @api private
  #
  # @see Hanami::Components
  module Components # rubocop:disable Metrics/ModuleLength
    # Require the entire project
    #
    # @since 0.9.0
    # @api private
    register 'all' do
      requires 'logger', 'mailer', 'code', 'model', 'apps', 'finalizers'

      resolve { true }
    end

    # Setup project's logger
    #
    # @since 1.0.0.beta1
    # @api private
    register 'logger' do
      prepare do
        require 'hanami/logger'
      end

      resolve do |configuration|
        Hanami::Logger.new(Hanami.environment.project_name, configuration.logger) unless configuration.logger.nil?
      end
    end

    # Check if code reloading is enabled
    #
    # @since 0.9.0
    # @api private
    register 'code_reloading' do
      prepare do
        begin
          require 'shotgun'
        rescue LoadError # rubocop:disable Lint/HandleExceptions
        end
      end

      resolve do
        !!(defined?(Shotgun) && # rubocop:disable Style/DoubleNegation
           Components['environment'].code_reloading?)
      end
    end

    register 'code' do
      run do
        directory = Hanami.root.join('lib')

        if Hanami.code_reloading?
          Utils.reload!(directory)
        else
          Utils.require!(directory)
        end
      end
    end

    # Tries to load hanami-model, if available for the project
    #
    # @since 0.9.0
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
      requires 'logger', 'model.configuration', 'model.sql'

      prepare do
        Hanami::Model.disconnect if Components['model.configuration']
      end

      resolve do
        if Components['model.configuration']
          Hanami::Model.load!
          Hanami::Model.configuration.logger = Components['logger']
          true
        end
      end
    end

    # Tries to evaluate hanami-model configuration, if available for the project
    #
    # @since 0.9.0
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
      requires 'model.bundled'

      resolve do |configuration|
        if Components['model.bundled']
          Hanami::Model.instance_variable_set(:@configuration, nil) if Hanami.code_reloading?
          Hanami::Model.configure(&configuration.model)
          Hanami::Model.configuration
        end
      end
    end

    # Tries to load SQL support for hanami, if available for the project
    #
    # @since 0.9.0
    # @api private
    #
    # @example With hanami-model
    #   Hanami::Components.resolve('model.sql')
    #   Hanami::Components['model.sql'] # => true
    #
    # @example Without hanami-model
    #   Hanami::Components.resolve('model.sql')
    #   Hanami::Components['model.sql'] # => nil
    register 'model.sql' do
      requires 'model.configuration'

      prepare do
        begin
          require 'hanami/model/sql'
        rescue LoadError # rubocop:disable Lint/HandleExceptions
        end
      end

      resolve do
        true if defined?(Hanami::Model::Sql)
      end
    end

    # Check if hanami-model is bundled
    #
    # @since 0.9.0
    # @api private
    #
    # @example With hanami-model
    #   Hanami::Components.resolve('model.bundled')
    #   Hanami::Components['model.bundled'] # => true
    #
    # @example Without hanami-model
    #   Hanami::Components.resolve('model.bundled')
    #   Hanami::Components['model.bundled'] # => nil
    register 'model.bundled' do
      prepare do
        begin
          require 'hanami/model'
        rescue LoadError # rubocop:disable Lint/HandleExceptions
        end
      end

      resolve do
        true if defined?(Hanami::Model)
      end
    end

    # Tries to evaluate hanami-mailer configuration
    #
    # @since 1.0.0.beta1
    # @api private
    #
    # @example With hanami-mailer
    #   Hanami::Components.resolve('mailer.configuration')
    #   Hanami::Components['mailer.configuration'].class # => Hanami::Mailer::Configuration
    register 'mailer.configuration' do
      prepare do
        require 'hanami/mailer'
        require 'hanami/mailer/glue'
      end

      resolve do |configuration|
        Hanami::Mailer.configuration = Hanami::Mailer::Configuration.new if Hanami.code_reloading?
        Hanami::Mailer.configure(&configuration.mailer)
        Hanami::Mailer.configuration
      end
    end

    # Tries to load hanami-mailer
    #
    # @since 1.0.0.beta1
    # @api private
    #
    # @example
    #   Hanami::Components.resolve('mailer')
    #   Hanami::Components['mailer'] # => true
    register 'mailer' do
      requires 'mailer.configuration'

      resolve do
        if Components['mailer.configuration']
          Hanami::Mailer.load!
          true
        end
      end
    end

    # Loads the routes for all the mounted Hanami/Rack applications
    #
    # This is used only by `hanami routes` command.
    #
    # @since 0.9.0
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
    # @since 0.9.0
    # @api private
    register 'apps' do
      resolve do |configuration|
        configuration.apps do |app|
          component('app').call(app)
        end

        true
      end
    end

    # Evaluates all the Hanami applications' configurations in the project
    #
    # @since 0.9.0
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
    # @since 0.9.0
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

    # Finalizers for the project
    #
    # @since 0.9.0
    # @api private
    register 'finalizers' do
      requires 'finalizers.initializers'

      resolve { true }
    end

    # Load project initializers
    #
    # @since 0.9.0
    # @api private
    register 'finalizers.initializers' do
      run do
        Hanami::Utils.require!(
          Hanami.root.join('config', 'initializers')
        )
      end
    end

    # Configure, load and finalize a Hanami application in the project
    #
    # @since 0.9.0
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
    # @since 0.9.0
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
    # @since 0.9.0
    # @api private
    register 'app.frameworks' do
      run do |app|
        ['app.controller', 'app.view', 'app.assets'].each do |c|
          component(c).call(app)
        end
      end
    end

    # Evaluate hanami-controller configuration of a single Hanami application in the project
    #
    # @since 0.9.0
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
    # @since 0.9.0
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
    # @since 0.9.0
    # @api private
    register 'app.assets' do
      prepare do
        require 'hanami/components/app/assets'
      end

      run do |app|
        Components::App::Assets.resolve(app)
      end
    end

    # Load the code for a single Hanami application in the project
    #
    # @since 0.9.0
    # @api private
    register 'app.code' do
      run do |app|
        config = app.configuration
        config.load_paths.load!
      end
    end

    # Load the routes for a single Hanami application in the project
    #
    # @since 0.9.0
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
    # @since 0.9.0
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
