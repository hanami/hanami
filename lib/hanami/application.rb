# frozen_string_literal: true

require "hanami/configuration"
require "pathname"
require "rack"
require_relative "application/container"
require_relative "slice"
require_relative "web/router"

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

          Hanami.application_class = klass
        end
      end
    end

    module ClassMethods
      def configuration
        @_configuration
      end

      alias_method :config, :configuration

      def container
        @_container ||= define_container
      end

      def slices
        @_slices ||= Dir[File.join(slices_path, "*")]
          .select(&File.method(:directory?))
          .map(&method(:load_slice))
      end

      alias_method :load_slices, :slices

      # Delegate some methods to container:
      def boot(*args, &block)
        container.boot(*args, &block)
      end
      def [](*args)
        container.[](*args)
      end

      def boot!(&block)
        container.configure do; end # force after configure hook

        container.finalize!(&block)

        slices.each do |slice|
          slice.boot!
        end

        self
      end

      def routes(&block)
        @_mutex.synchronize do
          if block.nil?
            raise "Hanami.application_class.routes not configured" unless defined?(@_routes)

            @_routes
          else
            @_routes = block
          end
        end
      end

      # TODO move somewhere more central
      MODULE_DELIMITER = "::"

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

      def define_container
        # TODO: raise error if constant already defined?

        Class.new(Container).tap do |container|
          container.configure do |config|
            config.auto_register = "lib/#{application_name}" # TODO: get from config somehow?
            config.default_namespace = application_name
          end

          # Any other config to pass in?

          const_set :Container, container
          application_module.const_set :Import, container.injector
        end
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
      # TODO: work out which params signature is actually better...

      # def initialize(
      #   configuration: self.class.configuration,
      #   container: self.class.container,
      #   slices: self.class.slices,
      #   routes: self.class.routes
      # )
      def initialize(application = self.class)
        application.boot!

        resolver = application.config.endpoint_resolver.new(
          container: application,
          namespace: application.config.action_key_namespace,
        )

        router = Web::Router.new(
          application: application,
          endpoint_resolver: resolver,
          &application.routes
        )

        # TODO: pass in configuration.router_settings somewhere

        @app = Rack::Builder.new do
          use application[:rack_monitor]

          # TODO: need to work out best way forward re: handling middlewares.
          # Declaring middlewares directly in routes is IMO the most flexible
          # option, but perhaps we might want to retain the idea of middleware
          # defined in the config, somehow?
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
