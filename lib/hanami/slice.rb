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

    def init
      container.import application: application.container

      slice_block = application.configuration.slices[name]
      instance_eval(&slice_block) if slice_block
    end

    def boot
      container.finalize! do
        container.config.env = application.container.config.env
      end

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
        container.import slice_name.to_sym => application.slices.fetch(slice_name.to_sym).container
      end
    end

    def register(*args, &block)
      container.register(*args, &block)
    end

    def register_bootable(*args, &block)
      container.boot(*args, &block)
    end

    def init_bootable(*args)
      container.init(*args)
    end

    def start_bootable(*args)
      container.start(*args)
    end

    def key?(*args)
      container.key?(*args)
    end

    def keys
      container.keys
    end

    def [](*args)
      container[*args]
    end

    def resolve(*args)
      container.resolve(*args)
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def define_container
      container = Class.new(Dry::System::Container)
      container.use :env

      container.configure do |config|
        config.name = name
        config.inflector = application.configuration.inflector

        config.component_dirs.loader = Dry::System::Loader::Autoloading
        config.component_dirs.add_to_load_path = false

        if root&.directory?
          config.root = root
          config.bootable_dirs = ["config/boot"]

          # Add component dirs for each configured component path
          application.configuration.source_dirs.component_dirs.each do |common_component_dir|
            next unless root.join(common_component_dir.path).directory?

            component_dir = common_component_dir.dup

            # TODO: this `== "lib"` check should be codified into a method somewhere
            if component_dir.path == "lib"
              # Expect component files in the root of the lib
              # component dir to define classes inside the slice's namespace.
              #
              # e.g. "lib/foo.rb" should define SliceNamespace::Foo, and will be
              # registered as "foo"
              component_dir.namespaces.root(key: nil, const: namespace_path)

              application.autoloader.push_dir(root.join("lib"), namespace: namespace)

              config.component_dirs.add_dir(component_dir)
            else
              # Expect component files in the root of these component dirs to define
              # classes inside a namespace matching the dir.
              #
              # e.g. "actions/foo.rb" should define SliceNamespace::Actions::Foo, and
              # will be registered as "actions.foo"

              dir_namespace_path = File.join(namespace_path, component_dir.path)

              autoloader_namespace = begin
                inflector.constantize(inflector.camelize(dir_namespace_path))
              rescue NameError
                namespace.const_set(inflector.camelize(component_dir.path), Module.new)
              end

              # TODO: do we need to do something special to clear out any previously configured root namespace here?
              component_dir.namespaces.root(const: dir_namespace_path, key: component_dir.path) # TODO: do we need to swap path delimiters for key delimiters here?
              config.component_dirs.add_dir(component_dir)

              application.autoloader.push_dir(
                container.root.join(component_dir.path),
                namespace: autoloader_namespace
              )
            end
          end
        end
      end

      if namespace
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end

      container
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
