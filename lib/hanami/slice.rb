# frozen_string_literal: true

require "dry/system/container"
require "pathname"

module Hanami
  class Slice
    attr_reader :application, :name, :namespace, :root

    def initialize(application, name:, namespace: nil, root: nil, container: nil)
      @application = application
      @name = name
      @namespace = namespace
      @root = root
      @container = container || define_container
    end

    def init
      container.import application: application.container

      if (slice_block = application.configuration.slices[name])
        instance_eval(&slice_block)
      end
    end

    def boot
      container.finalize! do
        container.config.env = application.container.config.env
      end

      @booted = true
      self
    end

    def booted?
      !!@booted
    end

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

    def define_container
      container = Class.new(Dry::System::Container)
      container.use :env

      container.config.name = name

      if root && File.directory?(root)
        container.config.root = root

        container.config.auto_register = ["lib/#{namespace_path}"]
        container.config.default_namespace = namespace_path.gsub("/", ".")

        container.load_paths! "lib"
      end

      container.configure do; end # force after configure hook

      if namespace
        namespace.const_set :Container, container
        namespace.const_set :Deps, container.injector
      end

      container
    end

    def namespace_path
      @namespace_path ||= inflector.underscore(namespace.to_s)
    end

    def inflector
      application.inflector
    end
  end
end
