# frozen_string_literal: true

require "dry/monitor"
require "dry/monitor/rack/middleware"
require "dry/system/container"
require "hanami/configuration"
require "pathname"
require "rack"
require_relative "slice"
require_relative "web/rack_logger"

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

      def init
        return self if inited?

        configuration.finalize

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

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def configure_container(container)
        container.use :env, inferrer: -> { Hanami.env }
        container.use :notifications

        container.config.root = configuration.root
        container.config.auto_register = "lib/#{application_name}"
        container.config.default_namespace = application_name

        # For after configure hook to run
        container.configure do; end # rubocop:disable Style/BlockDelimiters

        container.load_paths! "lib"

        # rubocop:disable Style/IfUnlessModifier
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
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
          root: slice_path.realpath.to_s
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def load_routes
        require File.join(configuration.root, configuration.routes)
      rescue LoadError # rubocop:disable Lint/HandleExceptions
      end
    end
    # rubocop:enable Metrics/ModuleLength

    # Application instance interface
    module InstanceMethods
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def initialize(application = self.class)
        require_relative "application/router"

        application.boot

        resolver = application.config.router_endpoint_resolver.new(
          container: application,
          namespace: application.config.router_endpoint_container_key_namespace,
        )

        router = Application::Router.new(
          context: application,
          endpoint_resolver: resolver,
          **application.configuration.router_settings,
          &application.routes
        )

        @app = Rack::Builder.new do
          use application[:rack_monitor]

          # Apply middleware from configuration
          application.config.for_each_middleware do |m, *args, &block|
            use(m, *args, &block)
          end

          run router
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def call(env)
        @app.call(env)
      end
    end
  end
end
