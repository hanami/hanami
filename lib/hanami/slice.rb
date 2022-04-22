# frozen_string_literal: true

require "dry/system/container"
require "hanami/errors"
require "pathname"
require_relative "constants"
require_relative "slice_name"
require_relative "slice_registrar"

module Hanami
  # Distinct area of concern within an Hanami application
  #
  # @since 2.0.0
  class Slice
    def self.inherited(subclass)
      super

      subclass.extend(ClassMethods)

      subclass.class_eval do
        @_mutex = Mutex.new
        @container = Class.new(Dry::System::Container)
      end
    end

    # rubocop:disable Metrics/ModuleLength
    module ClassMethods
      attr_reader :parent, :container

      def application
        Hanami.application
      end

      # A slice's configuration is copied from the application configuration, which should
      # have all settings configured before slices are loaded
      def configuration
        @configuration ||= application.configuration.dup.tap do |config|
          # Remove values from application that will not apply to this slice
          config.root = nil
        end
      end
      alias_method :config, :configuration

      def slice_name
        @slice_name ||= SliceName.new(self, inflector: method(:inflector))
      end

      def namespace
        slice_name.namespace
      end

      def root
        configuration.root
      end

      def inflector
        configuration.inflector
      end

      def prepare(provider_name = nil)
        if provider_name
          container.prepare(provider_name)
          self
        else
          prepare_slice
        end
      end

      def prepare_container(&block)
        @prepare_container_block = block
      end

      def boot
        return self if booted?

        prepare

        container.finalize!
        slices.each(&:boot)

        @booted = true

        self
      end

      def shutdown
        slices.each(&:shutdown)
        container.shutdown!
        self
      end

      def prepared?
        !!@prepared
      end

      def booted?
        !!@booted
      end

      def slices
        @slices ||= SliceRegistrar.new(self)
      end

      def register_slice(...)
        slices.register(...)
      end

      def register(...)
        container.register(...)
      end

      def register_provider(...)
        container.register_provider(...)
      end

      def start(...)
        container.start(...)
      end

      def key?(...)
        container.key?(...)
      end

      def keys
        container.keys
      end

      def [](...)
        container.[](...)
      end

      def resolve(...)
        container.resolve(...)
      end

      def export(keys)
        container.config.exports = keys
      end

      def import(from:, **kwargs)
        # TODO: This should be handled via dry-system (see dry-rb/dry-system#228)
        raise "Cannot import after booting" if booted?

        slice = self

        container.after(:configure) do
          if from.is_a?(Symbol) || from.is_a?(String)
            slice_name = from
            from = slice.parent.slices[from.to_sym].container
          end

          as = kwargs[:as] || slice_name

          import(from: from, as: as, **kwargs)
        end
      end

      def settings
        @settings ||= load_settings
      end

      def routes
        @routes ||= load_routes
      end

      def router
        raise SliceLoadError, "#{self} must be prepared before loading the router" unless prepared?

        @_mutex.synchronize do
          @_router ||= load_router
        end
      end

      def rack_app
        return unless router

        @rack_app ||= router.to_rack_app
      end

      private

      # rubocop:disable Metrics/AbcSize

      def prepare_slice
        return self if prepared?

        configuration.finalize!

        ensure_slice_name
        ensure_slice_consts
        ensure_root

        prepare_all

        container.configured!

        @prepared = true

        self
      end

      def ensure_slice_name
        unless name
          raise SliceLoadError, "Slice must have a class name before it can be prepared"
        end
      end

      def ensure_slice_consts
        if namespace.const_defined?(:Container) || namespace.const_defined?(:Deps)
          raise(
            SliceLoadError,
            "#{namespace}::Container and #{namespace}::Deps constants must not already be defined"
          )
        end
      end

      def ensure_root
        unless configuration.root
          raise SliceLoadError, "Slice must have a `config.root` before it can be prepared"
        end
      end

      def prepare_all
        # Load settings first, to fail early in case of missing/unexpected values
        settings

        prepare_container_consts
        prepare_container_plugins
        prepare_container_base_config
        prepare_container_component_dirs
        prepare_container_imports
        prepare_container_providers
        prepare_autoloader
        instance_exec(container, &@prepare_container_block) if @prepare_container_block

        prepare_slices
      end

      def prepare_container_plugins
        container.use(:env, inferrer: -> { Hanami.env })

        container.use(
          :zeitwerk,
          loader: application.autoloader,
          run_setup: false,
          eager_load: false
        )
      end

      def prepare_container_base_config
        container.config.name = slice_name.to_sym
        container.config.root = root
        container.config.provider_dirs = [File.join("config", "providers")]

        container.config.env = configuration.env
        container.config.inflector = configuration.inflector
      end

      def prepare_container_component_dirs
        return unless root.directory?

        # Don't auto-register files in `config/` or the configured no_auto_register_paths
        autoload_only_paths = ([CONFIG_DIR] + configuration.no_auto_register_paths)
          .map { |path|
            path.end_with?(File::SEPARATOR) ? path : "#{path}#{File::SEPARATOR}"
          }

        auto_register_proc = -> root {
          -> component {
            relative_path = component.file_path.relative_path_from(root).to_s
            !relative_path.start_with?(*autoload_only_paths)
          }
        }

        if root.join(LIB_DIR)&.directory?
          container.config.component_dirs.add(LIB_DIR) do |dir|
            dir.namespaces.add_root(key: nil, const: slice_name.name)
            dir.auto_register = auto_register_proc.(root.join(LIB_DIR))
          end
        end

        # TODO: Change `""` (signifying the root) once dry-rb/dry-system#238 is resolved
        container.config.component_dirs.add("") do |dir|
          # TODO: ignore lib/ child dir here
          dir.namespaces.add_root(key: nil, const: slice_name.name)
          dir.auto_register = auto_register_proc.(root)
        end
      end

      def prepare_container_imports
        import(
          keys: config.slices.shared_component_keys,
          from: application.container,
          as: nil
        )
      end

      def prepare_container_providers
        # Check here for the `routes` definition only, not `router` itself, because the
        # `router` requires the slice to be prepared before it can be loaded, and at this
        # point we're still in the process of preparing.
        if routes
          require_relative "providers/routes"
          register_provider(:routes, source: Hanami::Providers::Routes.for_slice(self))
        end

        if settings
          require_relative "providers/settings"
          register_provider(:settings, source: Hanami::Providers::Settings.for_slice(self))
        end
      end

      def prepare_autoloader
        # Everything in the slice directory can be autoloaded _except_ `config/`, which is
        # where we keep files loaded specially by the framework as part of slice setup.
        if root.join(CONFIG_DIR)&.directory?
          container.config.autoloader.ignore(root.join(CONFIG_DIR))
        end
      end

      def prepare_container_consts
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end

      def prepare_slices
        slices.load_slices.each(&:prepare)
        slices.freeze
      end

      def load_settings
        require_relative "./settings"

        if root.directory?
          settings_require_path = File.join(root, SETTINGS_PATH)

          begin
            require settings_require_path
          rescue LoadError => e
            raise e unless e.path == settings_require_path
          end
        end

        begin
          settings_class = autodiscover_application_constant(SETTINGS_CLASS_NAME)
          settings_class.new(configuration.settings_store)
        rescue NameError => e
          raise e unless e.name == SETTINGS_CLASS_NAME.to_sym
        end
      end

      def load_routes
        require_relative "./routes"

        if root.directory?
          routes_require_path = File.join(root, ROUTES_PATH)

          begin
            require routes_require_path
          rescue LoadError => e
            raise e unless e.path == routes_require_path
          end
        end

        begin
          routes_class = autodiscover_application_constant(ROUTES_CLASS_NAME)
          routes_class.routes
        rescue NameError => e
          raise e unless e.name == ROUTES_CLASS_NAME.to_sym
        end
      end

      def load_router
        return unless routes

        require_relative "slice/router"

        config = configuration
        rack_monitor = self["rack.monitor"]

        Slice::Router.new(routes: routes, resolver: router_resolver, **router_options) do
          use rack_monitor
          use config.sessions.middleware if config.sessions.enabled?

          middleware_stack.update(config.middleware_stack)
        end
      end

      def router_options
        configuration.router.options
      end

      def router_resolver
        configuration.router.resolver.new(slice: self)
      end

      def autodiscover_application_constant(constants)
        inflector.constantize([slice_name.namespace_name, *constants].join(MODULE_DELIMITER))
      end

      # rubocop:enable Metrics/AbcSize
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
