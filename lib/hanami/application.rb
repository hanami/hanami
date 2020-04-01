# frozen_string_literal: true

require "dry/monitor"
require "dry/monitor/rack/middleware"
require "dry/system/container"
require "hanami/configuration"
require "pathname"
require "rack"
require_relative "slice"
require_relative "web/rack_logger"
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

        load_routes

        @inited = true
        self
      end

      def inited?
        !!@inited # rubocop:disable Style/DoubleNegation
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

      def register(*args, &block)
        container.register(*args, &block)
      end

      def register_bootable(*args, &block)
        container.boot(*args, &block)
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

        container.finalize!(&block)

        slices.values.each(&:boot)

        @booted = true
        self
      end

      def booted?
        !!@booted # rubocop:disable Style/DoubleNegation
      end

      def settings(&block) # rubocop:disable Metrics/MethodLength
        if block
          @_settings = Application::Settings.build(
            configuration.settings_loader,
            configuration.settings_loader_options,
            &block
          )
        elsif instance_variable_defined?(:@_settings)
          @_settings
        else
          # Load settings lazily so they can be used to configure the
          # Hanami::Application subclass (before the application has inited)
          load_settings
          @_settings ||= nil
        end
      end

      def routes(&block)
        @_mutex.synchronize do
          if block.nil?
            raise "Hanami.application.routes not configured" unless defined?(@_routes)

            @_routes
          else
            @_routes = block
          end
        end
      end

      MODULE_DELIMITER = "::"
      private_constant :MODULE_DELIMITER

      def application_namespace
        inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
      end

      def application_name
        inflector.underscore(application_namespace).to_sym
      end

      def root
        configuration.root
      end

      def inflector
        configuration.inflector
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
        application_namespace.const_get :Container
      rescue LoadError, NameError
        application_namespace.const_set :Container, Class.new(Dry::System::Container)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      def configure_container(container)
        container.use :env, inferrer: -> { Hanami.env }
        container.use :notifications

        container.config.root = configuration.root
        container.config.auto_register = "lib/#{application_name}"
        container.config.default_namespace = application_name

        # For after configure hook to run
        container.configure do; end

        container.load_paths! "lib"

        # rubocop:disable Style/IfUnlessModifier
        if settings && !container.key?(:settings)
          container.register :settings, settings
        end

        unless container.key?(:inflector)
          container.register :inflector, inflector
        end

        unless container.key?(:logger)
          require "hanami/logger"
          container.register :logger, Hanami::Logger.new(configuration.logger)
        end

        unless container.key?(:rack_monitor)
          container.register :rack_monitor, Dry::Monitor::Rack::Middleware.new(container[:notifications])
        end

        unless container.key?(:rack_logger)
          container.register :rack_logger, Web::RackLogger.new(
            container[:logger],
            filter_params: configuration.rack_logger_filter_params,
          )
        end
        # rubocop:enable Style/IfUnlessModifier

        container[:rack_logger].attach container[:rack_monitor]

        container
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

      def define_deps_module
        require "#{application_name}/deps"
        application_namespace.const_get :Deps
      rescue LoadError, NameError
        application_namespace.const_set :Deps, container.injector
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

      def load_routes
        require File.join(configuration.root, configuration.router.routes)
      rescue LoadError # rubocop:disable Lint/SuppressedException
      end

      def load_settings
        prepare_base_load_path
        require File.join(configuration.root, configuration.settings_path)
      rescue LoadError # rubocop:disable Lint/SuppressedException
      end
    end
    # rubocop:enable Metrics/ModuleLength

    # Application instance interface
    module InstanceMethods
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def initialize(application = self.class)
        require_relative "application/router"

        application.boot

        resolver = application.config.router.resolver.new(
          slices: application.slices,
          inflector: application.inflector
        )

        router = Application::Router.new(
          routes: application.routes,
          resolver: resolver,
          **application.configuration.router.options,
        ) do
          use application[:rack_monitor]

          application.config.for_each_middleware do |m, *args, &block|
            use(m, *args, &block)
          end
        end

        @app = router.to_rack_app
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def call(env)
        @app.call(env)
      end
    end
  end
end
