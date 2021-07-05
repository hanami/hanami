# frozen_string_literal: true

require "dry/system/container"
require "hanami/configuration"
require "pathname"
require "rack"
require_relative "slice"
require_relative "application/autoloader/inflector_adapter"
require_relative "application/router"
require_relative "application/routes"
require_relative "application/settings"

module Hanami
  # Hanami application class
  #
  # @since 2.0.0
  class Application
    @_mutex = Mutex.new

    class << self
      def inherited(klass)
        @_mutex.synchronize do
          klass.class_eval do
            @_mutex         = Mutex.new
            @_configuration = Hanami::Configuration.new(env: Hanami.env)

            extend ClassMethods
            include InstanceMethods
          end

          klass.send :prepare_base_load_path

          Hanami.application = klass
        end
      end
    end

    # Application class interface
    #
    # rubocop:disable Metrics/ModuleLength
    module ClassMethods
      def self.extended(klass)
        klass.class_eval do
          @inited = @booted = false
        end
      end

      def configuration
        @_configuration
      end

      alias config configuration

      def init # rubocop:disable Metrics/MethodLength
        return self if inited?

        configuration.finalize

        load_settings

        @container = prepare_container
        @deps_module = prepare_deps_module

        load_slices
        slices.values.each(&:init)
        slices.freeze

        if configuration.autoloader
          configuration.autoloader.inflector = Autoloader::InflectorAdapter.new(inflector)
          configuration.autoloader.setup
        end

        @inited = true
        self
      end

      def inited?
        @inited
      end

      def container
        raise "Application not init'ed" unless defined?(@container)

        @container
      end

      def deps
        raise "Application not init'ed" unless defined?(@deps_module)

        @deps_module
      end

      def slices
        @slices ||= {}
      end

      def register_slice(name, **slice_args)
        raise "Slice +#{name}+ already registered" if slices.key?(name.to_sym)

        slice = Slice.new(self, name: name, **slice_args)
        slice.namespace.const_set :Slice, slice if slice.namespace # rubocop:disable Style/SafeNavigation
        slices[name.to_sym] = slice
      end

      def register(*args, **opts, &block)
        container.register(*args, **opts, &block)
      end

      def register_bootable(*args, **opts, &block)
        container.boot(*args, **opts, &block)
      end

      def init_bootable(*args)
        container.init(*args)
      end

      def start_bootable(*args)
        container.start(*args)
      end

      def key?(*args)
        container.key?(*args)
      end

      def keys
        container.keys
      end

      def [](*args)
        container[*args]
      end

      def resolve(*args)
        container.resolve(*args)
      end

      def boot(&block)
        return self if booted?

        init

        load_router

        container.finalize!(&block)

        slices.values.each(&:boot)

        @booted = true
        self
      end

      def booted?
        @booted
      end

      def settings
        @_settings ||= load_settings
      end

      MODULE_DELIMITER = "::"
      private_constant :MODULE_DELIMITER

      def namespace
        inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
      end

      def namespace_name
        namespace.name
      end

      def namespace_path
        inflector.underscore(namespace)
      end

      def application_name
        inflector.underscore(namespace).to_sym
      end

      def root
        configuration.root
      end

      def inflector
        configuration.inflector
      end

      # @api private
      def component_provider(component)
        raise "Hanami.application must be inited before detecting providers" unless inited?

        # [Admin, Main, MyApp] or [MyApp::Admin, MyApp::Main, MyApp]
        providers = slices.values + [self]

        component_class = component.is_a?(Class) ? component : component.class
        component_name = component_class.name

        return unless component_name

        providers.detect { |provider| component_name.include?(provider.namespace.to_s) }
      end

      def router
        @_mutex.synchronize do
          @_router ||= load_router
        end
      end

      def load_router
        Router.new(
          routes: routes,
          resolver: resolver,
          **configuration.router.options,
        ) do
          use Hanami.application[:rack_monitor]

          Hanami.application.config.for_each_middleware do |m, *args, &block|
            use(m, *args, &block)
          end
        end
      end

      def routes
        require File.join(configuration.root, configuration.routes_path)
        routes_class = autodiscover_application_constant(configuration.routes_class_name)
        routes_class.routes
      rescue LoadError
        proc {}
      end

      def resolver
        config.router.resolver.new(
          slices: slices,
          inflector: inflector
        )
      end

      private

      def prepare_base_load_path
        base_path = File.join(root, "lib")
        $LOAD_PATH.unshift base_path unless $LOAD_PATH.include?(base_path)
      end

      def prepare_container
        define_container.tap do |container|
          configure_container container
        end
      end

      def prepare_deps_module
        define_deps_module
      end

      def define_container
        require "#{application_name}/container"
        namespace.const_get :Container
      rescue LoadError, NameError
        namespace.const_set :Container, Class.new(Dry::System::Container)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      def configure_container(container)
        container.use :env, inferrer: -> { Hanami.env }
        container.use :notifications

        container.configure do |config|
          config.inflector = configuration.inflector

          config.root = configuration.root
          config.bootable_dirs = [
            "config/boot",
            Pathname(__dir__).join("application/container/boot").realpath,
          ]

          if configuration.autoloader
            require "dry/system/loader/autoloading"
            config.component_dirs.loader = Dry::System::Loader::Autoloading
            config.component_dirs.add_to_load_path = false
          end

          if root.join("lib").directory?
            config.component_dirs.add "lib" do |dir|
              dir.default_namespace = application_name.to_s
            end

            configuration.autoloader&.push_dir(root.join("lib"))
          end
        end

        container
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

      def define_deps_module
        require "#{application_name}/deps"
        namespace.const_get :Deps
      rescue LoadError, NameError
        namespace.const_set :Deps, container.injector
      end

      def load_slices
        Dir[File.join(slices_path, "*")]
          .select(&File.method(:directory?))
          .each(&method(:load_slice))
      end

      def slices_path
        File.join(root, config.slices_dir)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def load_slice(slice_path)
        slice_path = Pathname(slice_path)

        slice_name = slice_path.relative_path_from(Pathname(slices_path)).to_s
        slice_const_name = inflector.camelize(slice_name)

        if config.slices_namespace.const_defined?(slice_const_name)
          slice_module = config.slices_namespace.const_get(slice_const_name)

          raise "Cannot use slice +#{slice_const_name}+ since it is not a module" unless slice_module.is_a?(Module)
        else
          slice_module = Module.new
          config.slices_namespace.const_set inflector.camelize(slice_name), slice_module
        end

        register_slice(
          slice_name,
          namespace: slice_module,
          root: slice_path.realpath
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def load_settings
        prepare_base_load_path
        require File.join(configuration.root, configuration.settings_path)
        settings_class = autodiscover_application_constant(configuration.settings_class_name)
        settings_class.new(configuration.settings_store)
      rescue LoadError
        Settings.new
      end

      def autodiscover_application_constant(constants)
        inflector.constantize([namespace_name, *constants].join(MODULE_DELIMITER))
      end
    end
    # rubocop:enable Metrics/ModuleLength

    # Application instance interface
    module InstanceMethods
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def initialize(application = self.class)
        require_relative "application/router"

        application.boot

        @app = application.router.to_rack_app
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def call(env)
        @app.call(env)
      end
    end
  end
end
