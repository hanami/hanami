# frozen_string_literal: true

require_relative "configuration"
require_relative "constants"
require_relative "slice"
require_relative "slice_name"

module Hanami
  # The Hanami app is a singular slice tasked with managing the core components of
  # the app and coordinating overall app boot.
  #
  # For smaller apps, the app may be the only slice present, whereas larger apps
  # may consist of many slices, with the app reserved for holding a small number
  # of shared components only.
  #
  # @see Slice
  #
  # @api public
  # @since 2.0.0
  class App < Slice
    @_mutex = Mutex.new

    def self.inherited(subclass)
      super

      Hanami.app = subclass

      subclass.extend(ClassMethods)

      @_mutex.synchronize do
        subclass.class_eval do
          @configuration = Hanami::Configuration.new(app_name: slice_name, env: Hanami.env)

          prepare_base_load_path
        end
      end
    end

    # App class interface
    module ClassMethods
      attr_reader :configuration

      def app_name
        slice_name
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

        # Run specific prepare steps for the app slice. Note also that some
        # standard steps have been skipped via the empty method overrides below.
        prepare_app_component_dirs
        prepare_app_providers
      end

      # Skip standard slice prepare steps that do not apply to the app
      def prepare_container_component_dirs; end
      def prepare_container_imports; end

      # rubocop:disable Metrics/AbcSize

      def prepare_app_component_dirs
        # Component files in both `app/` and `app/lib/` define classes in the
        # app's namespace

        if root.join(APP_DIR, LIB_DIR).directory?
          container.config.component_dirs.add(File.join(APP_DIR, LIB_DIR)) do |dir|
            dir.namespaces.add_root(key: nil, const: app_name.name)
          end
        end

        # When auto-registering components in app/, ignore files in `app/lib/` (these will
        # be auto-registered as above), as well as the configured no_auto_register_paths
        no_auto_register_paths = ([LIB_DIR] + configuration.no_auto_register_paths)
          .map { |path|
            path.end_with?(File::SEPARATOR) ? path : "#{path}#{File::SEPARATOR}"
          }

        if root.join(APP_DIR).directory?
          container.config.component_dirs.add(APP_DIR) do |dir|
            dir.namespaces.add_root(key: nil, const: app_name.name)
            dir.auto_register = -> component {
              relative_path = component.file_path.relative_path_from(root.join(APP_DIR)).to_s
              !relative_path.start_with?(*no_auto_register_paths)
            }
          end
        end
      end

      def prepare_app_providers
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

      def prepare_autoloader
        # Component dirs are automatically pushed to the autoloader by dry-system's
        # zeitwerk plugin. This method adds other dirs that are not otherwise configured
        # as component dirs.

        # Autoload classes from `lib/[app_namespace]/`
        if root.join(LIB_DIR, app_name.name).directory?
          autoloader.push_dir(root.join(LIB_DIR, app_name.name), namespace: namespace)
        end

        autoloader.setup
      end

      # rubocop:enable Metrics/AbcSize
    end
  end
end
