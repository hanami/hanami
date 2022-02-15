# frozen_string_literal: true

require "dry/system/container"
require "pathname"

# Changes here
#
# 1. Requiring every slice to have an actual namespace (no more `if namespace` checks)

module Hanami
  # Distinct area of concern within an Hanami application
  #
  # @since 2.0.0
  class Slice
    # TODO: Move to a common constants file
    MODULE_DELIMITER = "::"
    private_constant :MODULE_DELIMITER

    class << self
      attr_reader :container

      def inherited(klass)
        super

        # Create a (to be configured later) container as early as possible, since code in
        # the slice subclass may want to start referring to it right away (e.g. `.import`)
        klass.instance_variable_set(:@container, Class.new(Dry::System::Container))
      end


      def namespace
        inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
      end

      def namespace_path
        inflector.underscore(namespace)
      end

      def slice_name
        inflector.underscore(name.split(MODULE_DELIMITER)[-2]).to_sym
      end

      def root
        application.root.join("slices", slice_name.to_s)
      end

      def inflector
        application.inflector
      end

      # rubocop:disable Style/DoubleNegation
      def prepared?
        !!@prepared
      end

      def booted?
        !!@booted
      end
      # rubocop:enable Style/DoubleNegation

      def prepare(provider_name = nil)
        container.prepare(provider_name) and return self if provider_name

        return self if prepared?

        __prepare_container

        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector

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

      def import(from:, **kwargs)
        # TODO: This should be handled via dry-system (see dry-rb/dry-system#228)
        raise "Cannot import after booting" if booted?

        application = self.application

        container.after(:configure) do
          if from.is_a?(Symbol) || from.is_a?(String)
            slice_name = from
            # TODO: better error than the KeyError from fetch if the slice doesn't exist
            from = application.slices.fetch(from.to_sym).container
          end

          as = kwargs[:as] || slice_name

          import(from: from, as: as, **kwargs)
        end
      end

      private

      def application
        Hanami.application
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def __prepare_container
        container.use :env
        container.use :zeitwerk,
          loader: application.autoloader,
          run_setup: false,
          eager_load: false

        container.config.name = slice_name
        container.config.env = application.configuration.env
        container.config.inflector = application.configuration.inflector

        if root&.directory?
          container.config.root = root
          container.config.provider_dirs = ["config/providers"]

          # Add component dirs for each configured component path
          application.configuration.source_dirs.component_dirs.each do |component_dir|
            next unless root.join(component_dir.path).directory?

            component_dir = component_dir.dup

            # TODO: this `== "lib"` check should be codified into a method somewhere
            if component_dir.path == "lib"
              # Expect component files in the root of the lib/ component dir to define
              # classes inside the slice's namespace.
              #
              # e.g. "lib/foo.rb" should define SliceNamespace::Foo, to be registered as
              # "foo"
              component_dir.namespaces.delete_root
              component_dir.namespaces.add_root(key: nil, const: namespace_path)

              container.config.component_dirs.add(component_dir)
            else
              # Expect component files in the root of non-lib/ component dirs to define
              # classes inside a namespace matching that dir.
              #
              # e.g. "actions/foo.rb" should define SliceNamespace::Actions::Foo, to be
              # registered as "actions.foo"

              dir_namespace_path = File.join(namespace_path, component_dir.path)

              component_dir.namespaces.delete_root
              component_dir.namespaces.add_root(const: dir_namespace_path, key: component_dir.path)

              container.config.component_dirs.add(component_dir)
            end
          end

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

        container.import from: application.container, as: :application

        instance_exec(container, &@prepare_container_block) if @prepare_container_block

        container.configured!

        container
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end
  end
end
