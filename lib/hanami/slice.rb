# frozen_string_literal: true

require "dry/system/container"
require "pathname"
require_relative "../hanami"

module Hanami
  class Slice < Dry::System::Container
    use :env, inferrer: -> { ENV.fetch("RACK_ENV", "development").to_sym }

    def self.inherited(klass)
      super

      if klass.superclass == Hanami::Slice
        raise "Hanami.application not configured yet" unless Hanami.application? # FIXME

        app = Hanami.application

        klass.instance_variable_set :@application, app

        klass.config.env = app.env
        klass.config.name = klass.slice_name.to_sym
        klass.config.auto_register = [File.join("lib", klass.slice_namespace_path)]
        klass.config.default_namespace = klass.slice_namespace_identifier_prefix

        slice_path = File.join(app.config.root, app.config.slices_dir, klass.slice_name)
        if File.directory?(slice_path)
          klass.config.root = slice_path if File.directory?(slice_path)
          klass.load_paths! "lib"

          if File.directory?(File.join(klass.config.root, klass.config.system_dir))
            klass.load_paths! klass.config.system_dir
          end
        end

        klass.import application: app
      end
    end

    def self.import_slice(*slices)
      @slice_imports ||= []
      @slice_imports += slices
      @slice_imports.uniq!
      self
    end

    def self.application
      @application
    end

    def self.boot!
      finalize!
    end

    def self.finalize!(*)
      return self if finalized?

      # Force `after :configure` hooks to run
      configure do; end

      super do
        Array(@slice_imports).each do |slice|
          import slice => application.slices.fetch(slice)
        end
      end
    end

    private

    MODULE_DELIMITER = "::"

    def self.slice_namespace
      inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
    end

    def self.slice_namespace_path
      inflector.underscore(slice_namespace.to_s)
    end

    def self.slice_namespace_identifier_prefix
      slice_namespace_path.gsub("/", ".")
    end

    def self.slice_name
      inflector.underscore(slice_namespace.to_s.split(MODULE_DELIMITER).last)
    end

    def self.inflector
      application[:inflector]
    end
  end
end
