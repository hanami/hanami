# frozen_string_literal: true

require "dry/system/container"
require "hanami/errors"
require "pathname"
require_relative "constants"

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
        inflector.underscore(name.split(MODULE_DELIMITER)[-2]).to_sym
      end

      def namespace
        inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
      end

      def namespace_path
        inflector.underscore(namespace)
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

      def prepare_container_base_config
        container.config.name = slice_name
        container.config.root = root
        container.config.provider_dirs = [File.join("config", "providers")]

        container.config.env = application.configuration.env
        container.config.inflector = application.configuration.inflector
      end

      def prepare_container_component_dirs # rubocop:disable Metrics/AbcSize
        return unless root&.directory?

        # Add component dirs for each configured component path
        application.configuration.source_dirs.component_dirs.each do |component_dir|
          next unless root.join(component_dir.path).directory?

          component_dir = component_dir.dup

          if component_dir.path == LIB_DIR
            # Expect component files in the root of the lib/ component dir to define
            # classes inside the slice's namespace.
            #
            # e.g. "lib/foo.rb" should define SliceNamespace::Foo, to be registered as
            # "foo"
            component_dir.namespaces.delete_root
            component_dir.namespaces.add_root(key: nil, const: namespace_path)
          else
            # Expect component files in the root of non-lib/ component dirs to define
            # classes inside a namespace matching that dir.
            #
            # e.g. "actions/foo.rb" should define SliceNamespace::Actions::Foo, to be
            # registered as "actions.foo"

            dir_namespace_path = File.join(namespace_path, component_dir.path)

            component_dir.namespaces.delete_root
            component_dir.namespaces.add_root(const: dir_namespace_path, key: component_dir.path)
          end

          container.config.component_dirs.add(component_dir)
        end
      end

      def prepare_autoloader # rubocop:disable Metrics/AbcSize
        return unless root&.directory?

        # Pass configured autoload dirs to the autoloader
        application.configuration.source_dirs.autoload_paths.each do |autoload_path|
          next unless root.join(autoload_path).directory?

          dir_namespace_path = File.join(namespace_path, autoload_path)

          autoloader_namespace = begin
            inflector.constantize(inflector.camelize(dir_namespace_path))
          rescue NameError
            namespace.const_set(inflector.camelize(autoload_path), Module.new)
          end

          container.config.autoloader.push_dir(
            container.root.join(autoload_path),
            namespace: autoloader_namespace
          )
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
