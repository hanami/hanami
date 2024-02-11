# frozen_string_literal: true

require "zeitwerk"
require "dry/system"

require_relative "constants"
require_relative "errors"

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

    # @api private
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
      # Returns the slice's parent.
      #
      # For top-level slices defined in `slices/` or `config/slices/`, this will be the Hanami app
      # itself (`Hanami.app`). For nested slices, this will be the slice in which they were
      # registered.
      #
      # @return [Hanami::Slice]
      #
      # @see #register_slice
      #
      # @api public
      # @since 2.0.0
      attr_reader :parent

      # Returns the slice's autoloader.
      #
      # Each slice has its own `Zeitwerk::Loader` autoloader instance, which is setup when the slice
      # is {#prepare prepared}.
      #
      # @return [Zeitwerk::Loader]
      #
      # @see https://github.com/fxn/zeitwerk
      #
      # @api public
      # @since 2.0.0
      attr_reader :autoloader

      # Returns the slice's container.
      #
      # This is a `Dry::System::Container` that is already configured for the slice.
      #
      # In ordinary usage, you shouldn't need direct access the container at all, since the slice
      # provides its own methods for interacting with the container (such as {#[]}, {#keys}, {#key?}
      # {#register}, {#register_provider}, {#prepare}, {#start}, {#stop}).
      #
      # If you need to configure the container directly, use {#prepare_container}.
      #
      # @see https://dry-rb.org/gems/dry-system
      #
      # @api public
      # @since 2.0.0
      attr_reader :container

      # Returns the Hanami app.
      #
      # @return [Hanami::App]
      #
      # @api public
      # @since 2.0.0
      def app
        Hanami.app
      end

      # Returns the slice's config.
      #
      # A slice's config is copied from the app config at time of first access.
      #
      # @return [Hanami::Config]
      #
      # @see App::ClassMethods.config
      #
      # @api public
      # @since 2.0.0
      def config
        @config ||= app.config.dup.tap do |slice_config|
          # Unset config from app that does not apply to ordinary slices
          slice_config.root = nil
        end
      end

      # Evaluates the block for a given app environment only.
      #
      # If the given `env_name` matches {Hanami.env}, then the block will be evaluated in the
      # context of `self` (the slice) via `instance_eval`. The slice is also passed as the block's
      # optional argument.
      #
      # If the env does not match, then the block is not evaluated at all.
      #
      # @example
      #   module MySlice
      #     class Slice < Hanami::Slice
      #       environment(:test) do
      #         config.logger.level = :info
      #       end
      #     end
      #   end
      #
      # @overload environment(env_name)
      #   @param env_name [Symbol] the environment name
      #
      # @overload environment(env_name)
      #   @param env_name [Symbol] the environment name
      #   @yieldparam slice [self] the slice
      #
      # @return [self]
      #
      # @see Hanami.env
      #
      # @api public
      # @since 2.0.0
      def environment(env_name, &block)
        instance_eval(&block) if env_name == config.env
        self
      end

      # Returns a {SliceName} for the slice, an object with methods returning the name of the slice
      # in various formats.
      #
      # @return [SliceName]
      #
      # @api public
      # @since 2.0.0
      def slice_name
        @slice_name ||= SliceName.new(self, inflector: method(:inflector))
      end

      # Returns the constant for the slice's module namespace.
      #
      # @example
      #   MySlice::Slice.namespace # => MySlice
      #
      # @return [Module] the namespace module constant
      #
      # @see SliceName#namespace
      #
      # @api public
      # @since 2.0.0
      def namespace
        slice_name.namespace
      end

      # Returns the slice's root, either the root as explicitly configured, or a default fallback of
      # the slice's name within the app's `slices/` dir.
      #
      # @return [Pathname]
      #
      # @see Config#root
      #
      # @api public
      # @since 2.0.0
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

      # Returns the slice's configured inflector.
      #
      # Unless explicitly re-configured for the slice, this will be the app's inflector.
      #
      # @return [Dry::Inflector]
      #
      # @see Config#inflector
      # @see Config#inflections
      #
      # @api public
      # @since 2.0.0
      def inflector
        config.inflector
      end

      # @overload prepare
      #   Prepares the slice.
      #
      #   This will define the slice's `Slice` and `Deps` constants, make all Ruby source files
      #   inside the slice's root dir autoloadable, as well as lazily loadable as container
      #   components.
      #
      #   Call `prepare` when you want to access particular components within the slice while still
      #   minimizing load time. Preparing slices is the approach taken when loading the Hanami
      #   console or when running tests.
      #
      #   @return [self]
      #
      #   @see #boot
      #
      #   @api public
      #   @since 2.0.0
      #
      # @overload prepare(provider_name)
      #   Prepares a provider.
      #
      #   This triggers the provider's `prepare` lifecycle step.
      #
      #   @param provider_name [Symbol] the name of the provider to start
      #
      #   @return [self]
      #
      #   @api public
      #   @since 2.0.0
      def prepare(provider_name = nil)
        if provider_name
          container.prepare(provider_name)
        else
          prepare_slice
        end

        self
      end

      # Captures the given block to be called with the slice's container during the slice's
      # `prepare` step, after the slice has already configured the container.
      #
      # This is intended for advanced usage only and should not be needed for ordinary slice
      # configuration and usage.
      #
      # @example
      #   module MySlice
      #     class Sliice < Hanami::Slice
      #       prepare_container do |container|
      #         # ...
      #       end
      #     end
      #   end
      #
      # @yieldparam container [Dry::System::Container] the slice's container
      #
      # @return [self]
      #
      # @see #prepare
      #
      # @api public
      # @since 2.0.0
      def prepare_container(&block)
        @prepare_container_block = block
        self
      end

      # Boots the slice.
      #
      # This will prepare the slice (if not already prepared), start each of its providers, register
      # all the slice's components from its Ruby source files, and import components from any other
      # slices. It will also boot any of the slice's own registered nested slices. It will then
      # freeze its container so no further components can be registered.
      #
      # Call `boot` if you want to fully load a slice and incur all load time up front, such as when
      # preparing an app to serve web requests. Booting slices is the approach taken when running
      # Hanami's standard Puma setup (see `config.ru`).
      #
      # @return [self]
      #
      # @see #prepare
      #
      # @api public
      # @since 2.0.0
      def boot
        return self if booted?

        prepare

        container.finalize!
        slices.each(&:boot)

        @booted = true

        self
      end

      # Shuts down the slice's providers, as well as the providers in any nested slices.
      #
      # @return [self]
      #
      # @api public
      # @since 2.0.0
      def shutdown
        slices.each(&:shutdown)
        container.shutdown!
        self
      end

      # Returns true if the slice has been prepared.
      #
      # @return [Boolean]
      #
      # @see #prepare
      #
      # @api public
      # @since 2.0.0
      def prepared?
        !!@prepared
      end

      # Returns true if the slice has been booted.
      #
      # @return [Boolean]
      #
      # @see #boot
      #
      # @api public
      # @since 2.0.0
      def booted?
        !!@booted
      end

      # Returns the slice's collection of nested slices.
      #
      # @return [SliceRegistrar]
      #
      # @see #register_slice
      #
      # @api public
      # @since 2.0.0
      def slices
        @slices ||= SliceRegistrar.new(self)
      end

      # @overload register_slice(name, &block)
      #   Registers a nested slice with the given name.
      #
      #   This will define a new {Slice} subclass for the slice. If a block is given, it is passed
      #   the class object, and will be evaluated in the context of the class like `class_eval`.
      #
      #   @example
      #     MySlice::Slice.register_slice do
      #       # Configure the slice or do other class-level things here
      #     end
      #
      #   @param name [Symbol] the identifier for the slice to be registered
      #   @yieldparam slice [Hanami::Slice] the newly defined slice class
      #
      # @overload register_slice(name, slice_class)
      #   Registers a nested slice with the given name.
      #
      #   The given `slice_class` will be registered as the slice. It must be a subclass of {Slice}.
      #
      #   @param name [Symbol] the identifier for the slice to be registered
      #   @param slice_class [Hanami::Slice]
      #
      # @return [slices]
      #
      # @see SliceRegistrar#register
      #
      # @api public
      # @since 2.0.0
      def register_slice(...)
        slices.register(...)
      end

      # Registers a component in the slice's container.
      #
      # @overload register(key, object)
      #   Registers the given object as the component. This same object will be returned whenever
      #   the component is resolved.
      #
      #   @param key [String] the component's key
      #   @param object [Object] the object to register as the component
      #
      # @overload reigster(key, memoize: false, &block)
      #   Registers the given block as the component. When the component is resolved, the return
      #   value of the block will be returned.
      #
      #   Since the block is not called until resolution-time, this is a useful way to register
      #   components that have dependencies on other components in the container, which as yet may
      #   be unavailable at the time of registration.
      #
      #   All auto-registered components are registered in block form.
      #
      #   When `memoize` is true, the component will be memoized upon first resolution and the same
      #   object returned on all subsequent resolutions, meaning the block is only called once.
      #   Otherwise, the block will be called and a new object returned on every resolution.
      #
      #   @param key [String] the component's key
      #   @param memoize [Boolean]
      #   @yieldreturn [Object] the object to register as the component
      #
      # @overload reigster(key, call: true, &block)
      #   Registers the given block as the component. When `call: false` is given, then the block
      #   itself will become the component.
      #
      #   When such a component is resolved, the block will not be called, and instead the `Proc`
      #   object for that block will be returned.
      #
      #   @param key [String] the component's key
      #   @param call [Booelan]
      #
      # @return [container]
      #
      # @see #[]
      # @see #resolve
      #
      # @api public
      # @since 2.0.0
      def register(...)
        container.register(...)
      end

      # @overload register_provider(name, namespace: nil, from: nil, source: nil, if: true, &block)
      #   Registers a provider and its lifecycle hooks.
      #
      #   In most cases, you should call this from a dedicated file for the provider in your app or
      #   slice's `config/providers/` dir. This allows the provider to be loaded when individual
      #   matching components are resolved (for prepared slices) or when slices are booted.
      #
      #   @example Simple provider
      #     # config/providers/db.rb
      #     Hanami.app.register_provider(:db) do
      #       start do
      #         require "db"
      #         register("db", DB.new)
      #       end
      #     end
      #
      #   @example Provider with lifecycle steps, also using dependencies from the target container
      #     # config/providers/db.rb
      #     Hanami.app.register_provider(:db) do
      #       prepare do
      #         require "db"
      #         db = DB.new(target_container["settings"].database_url)
      #         register("db", db)
      #       end
      #
      #       start do
      #         container["db"].establish_connection
      #       end
      #
      #       stop do
      #         container["db"].close_connection
      #       end
      #     end
      #
      #   @example Probvider registration under a namespace
      #     # config/providers/db.rb
      #     Hanami.app.register_provider(:persistence, namespace: true) do
      #       start do
      #         require "db"
      #
      #         # Namespace option above means this will be registered as "persistence.db"
      #         register("db", DB.new)
      #       end
      #     end
      #
      #   @param name [Symbol] the unique name for the provider
      #   @param namespace [Boolean, String, nil] register components from the provider with given
      #     namespace. May be an explicit string, or `true` for the namespace to be the provider's
      #     name
      #   @param from [Symbol, nil] the group for an external provider source to use, with the
      #     provider source name inferred from `name` or passsed explicitly as `source:`
      #   @param source [Symbol, nil] the name of the external provider source to use, if different
      #     from the value provided as `name`
      #   @param if [Boolean] a boolean-returning expression to determine whether to register the
      #     provider
      #
      #   @return [container]
      #
      #   @api public
      #   @since 2.0.0
      def register_provider(...)
        container.register_provider(...)
      end

      # @overload start(provider_name)
      #   Starts a provider.
      #
      #   This triggers the provider's `prepare` and `start` lifecycle steps.
      #
      #   @example
      #     MySlice::Slice.start(:persistence)
      #
      #   @param provider_name [Symbol] the name of the provider to start
      #
      #   @return [container]
      #
      #   @api public
      #   @since 2.0.0
      def start(...)
        container.start(...)
      end

      # @overload stop(provider_name)
      #   Stops a provider.
      #
      #   This triggers the provider's `stop` lifecycle hook.
      #
      #   @example
      #     MySlice::Slice.stop(:persistence)
      #
      #   @param provider_name [Symbol] the name of the provider to start
      #
      #   @return [container]
      #
      #   @api public
      #   @since 2.0.0
      def stop(...)
        container.stop(...)
      end

      # @overload key?(key)
      #   Returns true if the component with the given key is registered in the container.
      #
      #   For a prepared slice, calling `key?` will also try to load the component if not loaded
      #   already.
      #
      #   @param key [String, Symbol] the component key
      #
      #   @return [Boolean]
      #
      #   @api public
      #   @since 2.0.0
      def key?(...)
        container.key?(...)
      end

      # Returns an array of keys for all currently registered components in the container.
      #
      # For a prepared slice, this will be the set of components that have been previously resolved.
      # For a booted slice, this will be all components available for the slice.
      #
      # @return [Array<String>]
      #
      # @api public
      # @since 2.0.0
      def keys
        container.keys
      end

      # @overload [](key)
      #   Resolves the component with the given key from the container.
      #
      #   For a prepared slice, this will attempt to load and register the matching component if it
      #   is not loaded already. For a booted slice, this will return from already registered
      #   components only.
      #
      #   @return [Object] the resolved component's object
      #
      #   @raise Dry::Container::KeyError if the component could not be found or loaded
      #
      #   @see #resolve
      #
      #   @api public
      #   @since 2.0.0
      def [](...)
        container.[](...)
      end

      # @see #[]
      #
      # @api public
      # @since 2.0.0
      def resolve(...)
        container.resolve(...)
      end

      # Specifies the components to export from the slice.
      #
      # Slices importing from this slice can import the specified components only.
      #
      # @example
      #   module MySlice
      #     class Slice < Hanami::Slice
      #       export ["search", "index_entity"]
      #     end
      #   end
      #
      # @param keys [Array<String>] the component keys to export
      #
      # @return [self]
      #
      # @api public
      # @since 2.0.0
      def export(keys)
        container.config.exports = keys
        self
      end

      # @overload import(from:, as: nil, keys: nil)
      #   Specifies components to import from another slice.
      #
      #   Booting a slice will register all imported components. For a prepared slice, these
      #   components will be be imported automatically when resolved.
      #
      #   @example
      #     module MySlice
      #       class Slice < Hanami:Slice
      #         # Component from Search::Slice will import as "search.index_entity"
      #         import keys: ["index_entity"], from: :search
      #       end
      #     end
      #
      #   @example Other import variations
      #     # Different key namespace: component will be "search_backend.index_entity"
      #     import keys: ["index_entity"], from: :search, as: "search_backend"
      #
      #     # Import to root key namespace: component will be "index_entity"
      #     import keys: ["index_entity"], from: :search, as: nil
      #
      #     # Import all components
      #     import from: :search
      #
      #   @param keys [Array<String>, nil] Array of component keys to import. To import all
      #     available components, omit this argument.
      #   @param from [Symbol] name of the slice to import from
      #   @param as [Symbol, String, nil]
      #
      #   @see #export
      #
      #   @api public
      #   @since 2.0.0
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

      # Returns the slice's settings, or nil if no settings are defined.
      #
      # You can define your settings in `config/settings.rb`.
      #
      # @return [Hanami::Settings, nil]
      #
      # @see Hanami::Settings
      #
      # @api public
      # @since 2.0.0
      def settings
        return @settings if instance_variable_defined?(:@settings)

        @settings = Settings.load_for_slice(self)
      end

      # Returns the slice's routes, or nil if no routes are defined.
      #
      # You can define your routes in `config/routes.rb`.
      #
      # @return [Hanami::Routes, nil]
      #
      # @see Hanami::Routes
      #
      # @api public
      # @since 2.0.0
      def routes
        @routes ||= load_routes
      end

      # Returns the slice's router, if or nil if no routes are defined.
      #
      # An optional `inspector`, implementing the `Hanami::Router::Inspector` interface, may be
      # provided at first call (the router is then memoized for subsequent accesses). An inspector
      # is used by the `hanami routes` CLI comment to provide a list of available routes.
      #
      # The returned router is a {Slice::Router}, which provides all `Hanami::Router` functionality,
      # with the addition of support for slice mounting with the {Slice::Router#slice}.
      #
      # @param inspector [Hanami::Router::Inspector, nil] an optional routes inspector
      #
      # @return [Hanami::Slice::Router, nil]
      #
      # @api public
      # @since 2.0.0
      def router(inspector: nil)
        raise SliceLoadError, "#{self} must be prepared before loading the router" unless prepared?

        @_mutex.synchronize do
          @_router ||= load_router(inspector: inspector)
        end
      end

      # Returns a [Rack][rack] app for the slice, or nil if no routes are defined.
      #
      # The rack app will be memoized on first access.
      #
      # [rack]: https://github.com/rack/rack
      #
      # @return [#call, nil] the rack app, or nil if no routes are defined
      #
      # @see #routes
      # @see #router
      #
      # @api public
      # @since 2.0.0
      def rack_app
        return unless router

        @rack_app ||= router.to_rack_app
      end

      # @overload call(rack_env)
      #   Calls the slice's [Rack][rack] app and returns a Rack-compatible response object
      #
      #   [rack]: https://github.com/rack/rack
      #
      #   @param rack_env [Hash] the Rack environment for the request
      #
      #   @return [Array] the three-element Rack response array
      #
      #   @see #rack_app
      #
      #   @api public
      #   @since 2.0.0
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
        container.config.registrations_dir = File.join("config", "registrations")

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

        if assets_dir? && Hanami.bundled?("hanami-assets")
          require_relative "providers/assets"
          register_provider(:assets, source: Providers::Assets.for_slice(self))
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

        slice = self
        config = self.config
        rack_monitor = self["rack.monitor"]

        show_welcome = Hanami.env?(:development) && routes.empty?
        render_errors = render_errors?
        render_detailed_errors = render_detailed_errors?

        error_handlers = {}.tap do |hsh|
          if render_errors || render_detailed_errors
            hsh[:not_allowed] = ROUTER_NOT_ALLOWED_HANDLER
            hsh[:not_found] = ROUTER_NOT_FOUND_HANDLER
          end
        end

        Slice::Router.new(
          inspector: inspector,
          routes: routes,
          resolver: config.router.resolver.new(slice: self),
          **error_handlers,
          **config.router.options
        ) do
          use(rack_monitor)

          use(Hanami::Web::Welcome) if show_welcome

          use(
            Hanami::Middleware::RenderErrors,
            config,
            Hanami::Middleware::PublicErrorsApp.new(slice.root.join("public"))
          )

          if render_detailed_errors
            require "hanami/webconsole"
            use(Hanami::Webconsole::Middleware, config)
          end

          if Hanami.bundled?("hanami-controller")
            if config.actions.method_override
              require "rack/method_override"
              use(Rack::MethodOverride)
            end

            if config.actions.sessions.enabled?
              use(*config.actions.sessions.middleware)
            end
          end

          if Hanami.bundled?("hanami-assets") && config.assets.serve
            use(Hanami::Middleware::Assets)
          end

          middleware_stack.update(config.middleware_stack)
        end
      end

      def render_errors?
        config.render_errors
      end

      def render_detailed_errors?
        config.render_detailed_errors && Hanami.bundled?("hanami-webconsole")
      end

      ROUTER_NOT_ALLOWED_HANDLER = -> env, allowed_http_methods {
        raise Hanami::Router::NotAllowedError.new(env, allowed_http_methods)
      }.freeze
      private_constant :ROUTER_NOT_ALLOWED_HANDLER

      ROUTER_NOT_FOUND_HANDLER = -> env {
        raise Hanami::Router::NotFoundError.new(env)
      }.freeze
      private_constant :ROUTER_NOT_FOUND_HANDLER

      def assets_dir?
        assets_path = app.eql?(self) ? root.join("app", "assets") : root.join("assets")
        assets_path.directory?
      end

      # rubocop:enable Metrics/AbcSize
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
