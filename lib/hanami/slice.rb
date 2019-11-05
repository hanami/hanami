# frozen_string_literal: true

require "dry/system/container"
require "pathname"
require_relative "../hanami"

module Hanami
  class Slice
    attr_reader :application, :namespace, :root

    def initialize(application, namespace: nil, root: nil, container: nil)
      @application = application
      @namespace = namespace
      @root = root
      @container = container || define_container # TODO: better here, or lazily?
    end

    def name
      return unless namespace

      @name ||= inflector.underscore(namespace.to_s).split("/").last.to_sym
    end

    def container
      @container ||= define_container
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

    def keys
      container.keys
    end

    def [](*args)
      container[*args]
    end

    def resolve(*args)
      container.resolve(*args)
    end

    def boot
      container.configure do; end # force after configure hook

      # TODO: run finalize blocks somehow supplied by config?
      container.finalize!
    end

    private

    def define_container
      container = Class.new(Dry::System::Container)
      container.use :env
      container.config.env = application.container.config.env
      container.config.name = name

      if root && File.directory?(root)
        container.config.root = root

        container.config.auto_register = ["lib/#{namespace_path}"]
        container.config.default_namespace = namespace_path.gsub("/", ".")

        container.load_paths! "lib"
      end

      # FIXME: is this the right spot to be donig this?
      container.import application: application.container

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
