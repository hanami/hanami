# frozen_string_literal: true

require "dry/monitor"
require "dry/monitor/rack/middleware"
require "dry/system/container"
require "dry/system/components"
require "hanami/configuration"
require "pathname"
require "rack"
require_relative "slice"
require_relative "application/router"
require_relative "web/rack_logger"

module Hanami
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

    module ClassMethods
      def configuration
        @_configuration
      end

      alias_method :config, :configuration

      def init
        return self if inited?

        configuration.finalize

        @container = prepare_container
        @deps_module = prepare_deps_module
        @slices = load_slices
        @inited = true
        self
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
        raise "Application not init'ed" unless defined?(@slices)
        @slices
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

      def keys
        container.keys
      end

      def [](*args)
        container.[](*args)
      end

      def resolve(*args)
        container.resolve(*args)
      end

      def boot(&block)
        return self if booted?

        init

        container.configure do; end # force after configure hook

        container.finalize!(&block)

        slices.each do |slice|
          slice.boot
        end

        @booted = true
        self
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

      def application_module
        inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
      end

      def application_name
        inflector.underscore(application_module.to_s)
      end

      def root
        # TODO: do we need anything more sophisticated than this? This is how
        # Dry::System::Container determines its root by default, anyway.
        Dir.pwd
      end

      def inflector
        # TODO: might be good if we provided access as `config.inflector` too
        config.inflections
      end

      private

      def inited?
        !!@inited
      end

      def booted?
        !!@booted
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
        begin
          require "#{application_name}/container"
          application_module.const_get :Container
        rescue LoadError, NameError
          Class.new(Dry::System::Container).tap do |container|
            application_module.const_set :Container, container
          end
        end
      end

      def configure_container(container)
        container.use :env, inferrer: -> { Hanami.env }
        container.use :notifications

        container.configure do |config|
          config.auto_register = "lib/#{application_name}" # TODO: get from config somehow?
          config.default_namespace = application_name
        end

        container.load_paths! "lib"

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

        container[:rack_logger].attach container[:rack_monitor]

        # Any other config to pass in?

        container
      end

      def define_deps_module
        begin
          require "#{application_name}/deps"
          application_module.const_get :Deps
        rescue LoadError, NameError
          deps = container.injector
          application_module.const_set :Deps, deps
          deps
        end
      end

      def load_slices
        Dir[File.join(slices_path, "*")]
          .select(&File.method(:directory?))
          .map(&method(:load_slice))
      end

      def slices_path
        File.join(root, config.slices_dir)
      end

      def load_slice(slice_path)
        slice_name = Pathname(slice_path).relative_path_from(slices_path).to_s

        slice_module = Module.new
        config.slices_namespace.const_set inflector.camelize(slice_name), slice_module

        slice = Slice.new(
          self,
          namespace: slice_module,
          root: Pathname(slice_path).realpath.to_s,
        )
        slice_module.const_set :Slice, slice

        slice
      end
    end

    module InstanceMethods
      def initialize(application = self.class)
        application.boot

        resolver = application.config.endpoint_resolver.new(
          container: application,
          namespace: application.config.action_key_namespace,
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

          # Apply middleware definined inline in routes
          router.middlewares.each do |(*middleware, block)|
            use(*middleware, &block)
          end

          run router
        end
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
