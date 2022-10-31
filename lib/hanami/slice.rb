# frozen_string_literal: true

require "zeitwerk"
require "dry/system"

require_relative "../hanami"
require_relative "constants"
require_relative "errors"
require_relative "settings"
require_relative "slice_name"
require_relative "slice_registrar"

module Hanami
  # A slice represents any distinct area of concern within an Hanami app.
  #
  # For smaller apps, a slice may encompass the whole app itself (see
  # {Hanami::App}), whereas larger apps may consist of many slices.
  #
  # Each slice corresponds a single module namespace and a single root directory of source
  # files for loading as components into its container.
  #
  # Each slice has its own config, and may optionally have its own settings, routes, as well as
  # other nested slices.
  #
  # Slices expect an Hanami app to be defined (which itself is a slice). They will initialize their
  # config as a copy of the app's, and will also configure certain components
  #
  # Slices must be _prepared_ and optionally _booted_ before they can be used (see
  # {ClassMethods.prepare} and {ClassMethods.boot}). A prepared slice will lazily load its
  # components and nested slices (useful for minimising initial load time), whereas a
  # booted slice will eagerly load all its components and nested slices, then freeze its
  # container.
  #
  # @since 2.0.0
  class Slice
    @_mutex = Mutex.new

    def self.inherited(subclass)
      super

      subclass.extend(ClassMethods)

      @_mutex.synchronize do
        subclass.class_eval do
          @_mutex = Mutex.new
          @autoloader = Zeitwerk::Loader.new
          @container = Class.new(Dry::System::Container)
        end
      end
    end

    # rubocop:disable Metrics/ModuleLength
    module ClassMethods
      attr_reader :parent, :autoloader, :container

      def app
        Hanami.app
      end

      # A slice's config is copied from the app config at time of first access. The app should have
      # its config completed before slices are loaded.
      def config
        @config ||= app.config.dup.tap do |slice_config|
          # Remove specific values from app that will not apply to this slice
          slice_config.root = nil
        end
      end

      def slice_name
        @slice_name ||= SliceName.new(self, inflector: method(:inflector))
      end

      def namespace
        slice_name.namespace
      end

      def root
        # Provide a best guess for a root when it is not yet configured.
        #
        # This is particularly useful for user-defined slice classes that access `settings` inside
        # the class body (since the root needed to find the settings file). In this case,
        # `configuration.root` may be nil when `settings` is called, since the root is configured by
        # `SliceRegistrar#configure_slice` _after_ the class is loaded.
        #
        # In common cases, this best guess will be correct since most Hanami slices will be expected
        # to live in the app SLICES_DIR. For advanced cases, the correct slice root should be
        # explicitly configured at the beginning of the slice class body, before any calls to
        # `settings`.
        config.root || app.root.join(SLICES_DIR, slice_name.to_s)
      end

      def inflector
        config.inflector
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

      def stop(...)
        container.stop(...)
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
        return @settings if instance_variable_defined?(:@settings)

        @settings = Settings.load_for_slice(self)
      end

      def routes
        @routes ||= load_routes
      end

      def router(inspector: nil)
        raise SliceLoadError, "#{self} must be prepared before loading the router" unless prepared?

        @_mutex.synchronize do
          @_router ||= load_router(inspector: inspector)
        end
      end

      def rack_app
        return unless router

        @rack_app ||= router.to_rack_app
      end

      def call(...)
        rack_app.call(...)
      end

      private

      # rubocop:disable Metrics/AbcSize

      def prepare_slice
        return self if prepared?

        config.finalize!

        ensure_slice_name
        ensure_slice_consts
        ensure_root

        prepare_all

        instance_exec(container, &@prepare_container_block) if @prepare_container_block
        container.configured!

        prepare_autoloader

        # Load child slices last, ensuring their parent is fully prepared beforehand
        # (useful e.g. for slices that may wish to access constants defined in the
        # parent's autoloaded directories)
        prepare_slices

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
        unless config.root
          raise SliceLoadError, "Slice must have a `config.root` before it can be prepared"
        end
      end

      def prepare_all
        prepare_settings
        prepare_container_consts
        prepare_container_plugins
        prepare_container_base_config
        prepare_container_component_dirs
        prepare_container_imports
        prepare_container_providers
      end

      def prepare_settings
        container.register(:settings, settings) if settings
      end

      def prepare_container_consts
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end

      def prepare_container_plugins
        container.use(:env, inferrer: -> { Hanami.env })

        container.use(
          :zeitwerk,
          loader: autoloader,
          run_setup: false,
          eager_load: false
        )
      end

      def prepare_container_base_config
        container.config.name = slice_name.to_sym
        container.config.root = root
        container.config.provider_dirs = [File.join("config", "providers")]

        container.config.env = config.env
        container.config.inflector = config.inflector
      end

      def prepare_container_component_dirs
        return unless root.directory?

        # Component files in both the root and `lib/` define classes in the slice's
        # namespace

        if root.join(LIB_DIR)&.directory?
          container.config.component_dirs.add(LIB_DIR) do |dir|
            dir.namespaces.add_root(key: nil, const: slice_name.name)
          end
        end

        # When auto-registering components in the root, ignore files in `config/` (this is
        # for framework config only), `lib/` (these will be auto-registered as above), as
        # well as the configured no_auto_register_paths
        no_auto_register_paths = ([LIB_DIR, CONFIG_DIR] + config.no_auto_register_paths)
          .map { |path|
            path.end_with?(File::SEPARATOR) ? path : "#{path}#{File::SEPARATOR}"
          }

        # TODO: Change `""` (signifying the root) once dry-rb/dry-system#238 is resolved
        container.config.component_dirs.add("") do |dir|
          dir.namespaces.add_root(key: nil, const: slice_name.name)
          dir.auto_register = -> component {
            relative_path = component.file_path.relative_path_from(root).to_s
            !relative_path.start_with?(*no_auto_register_paths)
          }
        end
      end

      def prepare_container_imports
        import(
          keys: config.shared_app_component_keys,
          from: app.container,
          as: nil
        )
      end

      def prepare_container_providers
        # Check here for the `routes` definition only, not `router` itself, because the
        # `router` requires the slice to be prepared before it can be loaded, and at this
        # point we're still in the process of preparing.
        if routes
          require_relative "providers/routes"
          register_provider(:routes, source: Providers::Routes.for_slice(self))
        end
      end

      def prepare_autoloader
        # Component dirs are automatically pushed to the autoloader by dry-system's
        # zeitwerk plugin. This method adds other dirs that are not otherwise configured
        # as component dirs.

        # Everything in the slice root can be autoloaded except `config/` and `slices/`,
        # which are framework-managed directories

        if root.join(CONFIG_DIR)&.directory?
          autoloader.ignore(root.join(CONFIG_DIR))
        end

        if root.join(SLICES_DIR)&.directory?
          autoloader.ignore(root.join(SLICES_DIR))
        end

        autoloader.setup
      end

      def prepare_slices
        slices.load_slices.each(&:prepare)
        slices.freeze
      end

      def load_routes
        return false unless Hanami.bundled?("hanami-router")

        if root.directory?
          routes_require_path = File.join(root, ROUTES_PATH)

          begin
            require_relative "./routes"
            require routes_require_path
          rescue LoadError => e
            raise e unless e.path == routes_require_path
          end
        end

        begin
          routes_class = namespace.const_get(ROUTES_CLASS_NAME)
          routes_class.routes
        rescue NameError => e
          raise e unless e.name == ROUTES_CLASS_NAME.to_sym
        end
      end

      def load_router(inspector:)
        return unless routes

        require_relative "slice/router"

        config = self.config
        rack_monitor = self["rack.monitor"]

        Slice::Router.new(
          inspector: inspector,
          routes: routes,
          resolver: config.router.resolver.new(slice: self),
          **config.router.options
        ) do
          use(rack_monitor)
          use(*config.sessions.middleware) if config.sessions.enabled?

          middleware_stack.update(config.middleware_stack)
        end
      end

      # rubocop:enable Metrics/AbcSize
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
