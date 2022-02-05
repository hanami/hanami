# frozen_string_literal: true

require "dry/system/container"
require "dry/system/loader/autoloading"
require "pathname"

module Hanami
  # Distinct area of concern within an Hanami application
  #
  # @since 2.0.0
  class Slice
    attr_reader :application, :name, :namespace, :root

    def initialize(application, name:, namespace: nil, root: nil, container: nil)
      @application = application
      @name = name.to_sym
      @namespace = namespace
      @root = root ? Pathname(root) : root
      @container = container || define_container
    end

    def inflector
      application.inflector
    end

    def namespace_path
      @namespace_path ||= inflector.underscore(namespace.to_s)
    end

    def prepare(provider_name = nil)
      if provider_name
        container.prepare(provider_name)
        return self
      end

      container.import from: application.container, as: :application

      slice_block = application.configuration.slices[name]
      instance_eval(&slice_block) if slice_block

      self
    end

    def boot
      container.finalize!

      @booted = true
      self
    end

    # rubocop:disable Style/DoubleNegation
    def booted?
      !!@booted
    end
    # rubocop:enable Style/DoubleNegation

    def container
      @container ||= define_container
    end

    def import(*slice_names)
      raise "Cannot import after booting" if booted?

      slice_names.each do |slice_name|
        container.import from: application.slices.fetch(slice_name.to_sym).container, as: slice_name.to_sym
      end
    end

    def register(*args, &block)
      container.register(*args, &block)
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

    private

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def define_container
      container = Class.new(Dry::System::Container)
      container.use :env

      container.config.name = name
      container.config.env = application.configuration.env
      container.config.inflector = application.configuration.inflector

      container.config.component_dirs.loader = Dry::System::Loader::Autoloading
      container.config.component_dirs.add_to_load_path = false

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

            application.autoloader.push_dir(root.join("lib"), namespace: namespace)
          else
            # Expect component files in the root of non-lib/ component dirs to define
            # classes inside a namespace matching that dir.
            #
            # e.g. "actions/foo.rb" should define SliceNamespace::Actions::Foo, to be
            # registered as "actions.foo"

            dir_namespace_path = File.join(namespace_path, component_dir.path)

            autoloader_namespace = begin
              inflector.constantize(inflector.camelize(dir_namespace_path))
            rescue NameError
              namespace.const_set(inflector.camelize(component_dir.path), Module.new)
            end

            component_dir.namespaces.delete_root
            component_dir.namespaces.add_root(const: dir_namespace_path, key: component_dir.path) # TODO: do we need to swap path delimiters for key delimiters here?

            container.config.component_dirs.add(component_dir)

            application.autoloader.push_dir(
              container.root.join(component_dir.path),
              namespace: autoloader_namespace
            )
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

          application.autoloader.push_dir(
            container.root.join(autoload_path),
            namespace: autoloader_namespace
          )
        end
      end

      if namespace
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end

      container.configured!
      container
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
