# frozen_string_literal: true

require "dry/system/container"
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

      container.config.name = name
      container.config.inflector = application.configuration.inflector

      if root && File.directory?(root)
        container.config.root = root
        container.config.bootable_dirs = ["config/boot"]

        container.config.auto_register = ["lib/#{namespace_path}"]
        container.config.default_namespace = namespace_path.tr("/", ".")

        container.load_paths! "lib"
      end

      # Force after configure hook to run
      container.configure do; end

      if namespace
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end

      container
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
