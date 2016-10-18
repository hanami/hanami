require 'concurrent'

module Hanami
  # Components
  #
  # @since x.x.x
  module Components
    class Component
      attr_reader :name
      attr_reader :requirements
      attr_accessor :_prepare, :_resolve, :_run

      def initialize(name, &blk)
        @name         = name
        @requirements = []
        @_prepare     = ->(*) {}
        @_resolve     = -> {}
        instance_eval(&blk)
      end

      def requires(*components)
        self.requirements = Array(components).flatten
      end

      def prepare(&blk)
        self._prepare = blk
      end

      def resolve(&blk)
        self._resolve = blk
      end

      def run(&blk)
        self._run = blk
      end

      def call(configuration)
        resolve_requirements
        _prepare.call(configuration)

        unless _run.nil?
          _run.call(configuration)
          return
        end

        resolved(name, _resolve.call(configuration))
      end

      def resolve_requirements
        Components.resolve(requirements)
      end

      def requirements=(names)
        @requirements = Array(names).flatten
      end

      def component(name)
        Components.component(name)
      end

      def resolved(name, value = nil, &blk)
        Components.resolved(name, value, &blk)
      end
    end

    # FIXME: review if this is the right data structure for @_components
    @_components = Concurrent::Hash.new
    @_resolved   = Concurrent::Map.new

    def self.register(name, &blk)
      @_components[name] = Component.new(name, &blk)
    end

    def self.component(name)
      @_components.fetch(name)
    end

    def self.resolved(name, value = nil, &blk)
      if block_given?
        @_resolved.fetch_or_store(name, &blk)
      else
        @_resolved.merge_pair(name, value)
      end
    end

    def self.resolve(names)
      Array(names).flatten.each do |name|
        @_resolved.fetch_or_store(name) do
          component = @_components.fetch(name)
          component.call(Hanami.configuration)
        end
      end
    end

    def self.[](name)
      @_resolved.fetch(name) do
        raise ArgumentError.new("Component not found: `#{name}'.\nAvailable components are: #{@_resolved.keys.join(', ')}")
      end
    end

    register 'all' do
      requires 'model', 'apps'

      run do
        Hanami.boot # FIXME: This should require components instead of using Hanami.boot
      end
    end

    register 'model' do
      requires 'model.configuration'

      run do
        Hanami::Model.load! if defined?(Hanami::Model)
      end
    end

    register 'model.configuration' do
      prepare do
        require 'hanami/model'
      end

      resolve do |configuration|
        Hanami::Model.configure(&configuration.model)
        Hanami::Model.configuration
      end
    end

    register 'routes.inspector' do
      requires 'apps.configurations'

      prepare do
        require 'hanami/components/routes_inspector'
      end

      resolve do |configuration|
        RoutesInspector.new(configuration)
      end
    end

    register 'apps' do
      run do |configuration|
        configuration.apps do |app|
          component('app').call(app)
        end
      end
    end

    register 'apps.configurations' do
      resolve do |configuration|
        configuration.apps do |app|
          component('app.configuration').call(app)
        end

        true
      end
    end

    register 'apps.assets.configurations' do
      requires 'apps.configurations'

      resolve do |configuration|
        result = []
        configuration.apps do |app|
          # FIXME: this has to be unified with app.assets
          config = app.configuration

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
          end

          assets.cdn assets.host != config.host

          result << assets
        end

        result
      end
    end

    register 'app' do
      run do |app|
        ['app.configuration', 'app.frameworks', 'app.code', 'app.routes', 'app.finalizer'].each do |c|
          component(c).call(app)
        end
      end
    end

    register 'app.configuration' do
      run do |app|
        resolved("#{app.app_name}.configuration") do
          ApplicationConfiguration.new(app.namespace, app.configurations, app.path_prefix).tap do |config|
            app.configuration = config
          end
        end
      end
    end

    register 'app.frameworks' do
      run do |app|
        ['app.controller', 'app.view', 'app.assets', 'app.logger'].each do |c|
          component(c).call(app)
        end
      end
    end

    register 'app.controller' do
      prepare do
        require 'hanami/components/app/controller'
      end

      # FIXME: Once we'll get configurations to work, use:
      #
      # resolve do
      #   Controller.new(app)
      # end

      run do |app|
        Components::App::Controller.resolve(app)
      end
    end

    register 'app.view' do
      prepare do
        require 'hanami/components/app/view'
      end

      # FIXME: Once we'll get configurations to work, use:
      #
      # resolve do
      #   View.new(app)
      # end

      run do |app|
        Components::App::View.resolve(app)
      end
    end

    register 'app.assets' do
      prepare do
        require 'hanami/components/app/assets'
      end

      # FIXME: Once we'll get configurations to work, use:
      #
      # resolve do
      #   Assets.new(app)
      # end

      run do |app|
        Components::App::Assets.resolve(app)
      end
    end

    register 'app.logger' do
      prepare do
        require 'hanami/components/app/logger'
      end

      # FIXME: Once we'll get configurations to work, use:
      #
      # resolve do
      #   Logger.new(app)
      # end

      run do |app|
        Components::App::Logger.resolve(app)
      end
    end

    register 'app.code' do
      run do |app|
        config = app.configuration
        config.load_paths.load!(config.root) # TODO: check why config.root has to be passed
      end
    end

    register 'app.routes' do
      prepare do
        require 'hanami/components/app/routes'
      end

      # FIXME: Once we'll get configurations to work, use:
      #
      # resolve do
      #   Routes.new(app)
      # end

      run do |app|
        Components::App::Routes.resolve(app)
      end
    end

    register 'app.finalizer' do
      run do |app|
        config    = app.configuration
        namespace = app.namespace

        config.middleware.load!(app, namespace)

        namespace.module_eval %(#{namespace}::Controller.load!)
        namespace.module_eval %(#{namespace}::View.load!)
        namespace.module_eval %(#{namespace}::Assets.load!)
      end
    end
  end
end
