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

    def [](*args)
      container.[](*args)
    end

    def boot!
      container.configure do; end # force after configure hook

      # TODO: run finalize blocks somehow supplied by config?
      container.finalize!
    end

    class Container < Dry::System::Container
      use :env

      # TODO: work out if we want any more custom logic here?
    end

    private

    def define_container
      container = Class.new(Container)
      container.config.env = Hanami.env
      container.config.name = name

      if root && File.directory?(root)
        container.config.root = root

        container.config.auto_register = ["lib/#{namespace_path}"]
        container.config.default_namespace = namespace_path.gsub("/", ".")

        # TODO: add system_dir to load paths?
        container.load_paths! "lib"
      end

      # TODO: is this the right spot to be donig this?
      container.import application: application.container

      if namespace
        namespace.const_set :Container, container
        namespace.const_set :Import, container.injector
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
