# frozen_string_literal: true

require "dry/system/container"
require "forwardable"

require "pathname"
require "rack"
require "zeitwerk"
require_relative "constants"
require_relative "slice"
require_relative "slice_name"

module Hanami
  # Hanami application class
  #
  # @since 2.0.0
  class Application < Slice
    require "hanami/configuration"

    @_mutex = Mutex.new

    def self.inherited(subclass)
      super

      @_mutex.synchronize do
        Hanami.application = subclass

        subclass.extend ClassMethods

        subclass.class_eval do
          @_mutex = Mutex.new
          @slice_name = SliceName.new(subclass, inflector: -> { subclass.inflector })
          @configuration = Hanami::Configuration.new(application_name: @slice_name, env: Hanami.env)
          @autoloader = Zeitwerk::Loader.new

          prepare_base_load_path
        end
      end
    end

    # Application class interface
    module ClassMethods
      attr_reader :autoloader, :configuration

      def application_name
        slice_name
      end

      def root
        configuration.root
      end

      private

      def prepare_base_load_path
        base_path = root.join(LIB_DIR)
        $LOAD_PATH.unshift(base_path) unless $LOAD_PATH.include?(base_path)
      end

      def prepare_all
        # Make app-wide notifications available as early as possible
        container.use(:notifications)

        # Ensure all basic slice preparation is complete before we make adjustments below
        # (which rely on the basic prepare steps having already run)
        super

        # Run specific prepare steps for the application slice. Note also that some
        # standard steps have been skipped via the empty method overrides below.
        prepare_application_component_dirs
        prepare_application_providers

        # The autoloader must be setup after the container is configured, which is the
        # point at which any registered component dirs from other slices are added to the
        # autoloader
        app = self
        container.after(:configure) do
          app.send(:prepare_application_autoloader)
        end
      end

      # Skip standard slice prepare steps that do not apply to the application slice
      def prepare_container_component_dirs; end
      def prepare_container_imports; end

      def prepare_application_component_dirs
        # Component files in both `app/` and `app/lib/` define classes in the
        # application's namespace

        if root.join(APP_DIR, LIB_DIR).directory?
          container.config.component_dirs.add(File.join(APP_DIR, LIB_DIR)) do |dir|
            dir.namespaces.add_root(key: nil, const: application_name.name)
          end
        end

        if root.join(APP_DIR).directory?
          # TODO: ignore lib/ child dir here
          container.config.component_dirs.add(APP_DIR) do |dir|
            dir.namespaces.add_root(key: nil, const: application_name.name)
          end
        end
      end

      def prepare_application_providers
        require_relative "providers/inflector"
        register_provider(:inflector, source: Hanami::Providers::Inflector)

        # Allow logger to be replaced by users with a manual provider, for advanced cases
        unless container.providers.find_and_load_provider(:logger)
          require_relative "providers/logger"
          register_provider(:logger, source: Hanami::Providers::Logger)
        end

        require_relative "providers/rack"
        register_provider(:rack, source: Hanami::Providers::Rack, namespace: true)
      end

      def prepare_application_autoloader
        # Component dirs are automatically pushed to the autoloader by dry-system's
        # zeitwerk plugin. This method adds other dirs that are not otherwise configured
        # as component dirs.

        # Autoload classes from `lib/[app_namespace]/`
        if root.join(LIB_DIR, application_name.name).directory?
          autoloader.push_dir(root.join(LIB_DIR, application_name.name), namespace: namespace)
        end

        autoloader.setup
      end
    end
  end
end
