# frozen_string_literal: true

require "dry/system/container"
require "hanami/errors"
require "pathname"
require_relative "constants"
require_relative "slice_name"

module Hanami
  # Distinct area of concern within an Hanami application
  #
  # @since 2.0.0
  class Slice
    def self.inherited(subclass)
      super

      subclass.extend(ClassMethods)

      # Eagerly initialize any variables that may be accessed inside the subclass body
      subclass.instance_variable_set(:@application, Hanami.application)
      subclass.instance_variable_set(:@container, Class.new(Dry::System::Container))
    end

    # rubocop:disable Metrics/ModuleLength
    module ClassMethods
      attr_reader :application, :container

      def slice_name
        @slice_name ||= SliceName.new(self, inflector: method(:inflector))
      end

      def namespace
        slice_name.namespace
      end

      def root
        application.root.join(SLICES_DIR, slice_name.to_s)
      end

      def inflector
        application.inflector
      end

      def prepare(provider_name = nil)
        container.prepare(provider_name) and return self if provider_name

        return self if prepared?

        ensure_slice_name
        ensure_slice_consts

        prepare_all

        @prepared = true
        self
      end

      def prepare_container(&block)
        @prepare_container_block = block
      end

      def boot
        return self if booted?

        container.finalize!

        @booted = true

        self
      end

      def shutdown
        container.shutdown!
        self
      end

      def prepared?
        !!@prepared
      end

      def booted?
        !!@booted
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

        application = self.application

        container.after(:configure) do
          if from.is_a?(Symbol) || from.is_a?(String)
            slice_name = from
            from = application.slices[from.to_sym].container
          end

          as = kwargs[:as] || slice_name

          import(from: from, as: as, **kwargs)
        end
      end

      private

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

      def prepare_all
        prepare_container_plugins
        prepare_container_base_config
        prepare_container_component_dirs
        prepare_autoloader
        prepare_container_imports
        prepare_container_consts
        instance_exec(container, &@prepare_container_block) if @prepare_container_block
        container.configured!
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

      def prepare_container_base_config # rubocop:disable Metrics/AbcSize
        container.config.name = slice_name.to_sym
        container.config.root = root
        container.config.provider_dirs = [File.join("config", "providers")]

        container.config.env = application.configuration.env
        container.config.inflector = application.configuration.inflector
      end

      def prepare_container_component_dirs # rubocop:disable Metrics/AbcSize
        return unless root&.directory?

        # Don't auto-register files in `config/` or the configured no_auto_register_paths
        autoload_only_paths = ([CONFIG_DIR] + application.configuration.no_auto_register_paths)
          .map { |path|
            path.end_with?(File::SEPARATOR) ? path : "#{path}#{File::SEPARATOR}"
          }

        auto_register_proc = -> root {
          -> component {
            relative_path = component.file_path.relative_path_from(root).to_s
            !relative_path.start_with?(*autoload_only_paths)
          }
        }

        if root&.join(LIB_DIR)&.directory?
          container.config.component_dirs.add(LIB_DIR) do |dir|
            dir.namespaces.add_root(key: nil, const: slice_name.name)
            dir.auto_register = auto_register_proc.(root.join(LIB_DIR))
          end
        end

        # TODO: Change `""` (signifying the root) once dry-rb/dry-system#238 is resolved
        container.config.component_dirs.add("") do |dir|
          dir.namespaces.add_root(key: nil, const: slice_name.name)
          dir.auto_register = auto_register_proc.(root)
        end
      end

      def prepare_autoloader
        # Everything in the slice directory can be autoloaded _except_ `config/`, which is
        # where we keep files loaded specially by the framework as part of slice setup.
        if root&.join(CONFIG_DIR)&.directory?
          container.config.autoloader.ignore(root.join(CONFIG_DIR))
        end
      end

      def prepare_container_imports
        container.import from: application.container, as: :application
      end

      def prepare_container_consts
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
