# frozen_string_literal: true

require_relative "../hanami"
require "hanami/configuration"
require "hanami/routes"
require "hanami/router"

# These are all for the new Application
require "dry/inflector"
require "dry/monitor" # from dry-web, TODO: remove
require "dry/system/container"
require "dry/system/components"

module Hanami
  class Application < Dry::System::Container
    setting :inflector, Dry::Inflector.new, reader: true
    setting :slices_dir, "slices"

    use :env, inferrer: -> { ENV.fetch("RACK_ENV", "development").to_sym }
    use :logging
    use :notifications
    use :monitoring

    @_mutex = Mutex.new

    # From old application
    module ClassMethods
      def configuration
        @_configuration
      end

      # FIXME: I had to remove this alias since `.config` is used by
      # Dry::System::Container's own dry-configurable-provided settings
      #
      # alias config configuration
    end

    def self.inherited(app_class)
      super

      # This block is from the previous version of Hanami::Application. Need to
      # work out just how exactly to nicely merge it into the new structure
      @_mutex.synchronize do
        app_class.class_eval do
          # @_mutex         = Mutex.new

          # Is this a problem given we'll be setting this before the subclass
          # gets a chance to perhaps change its own env?
          #
          # OK, this is actually a problem, since accessing the config and
          # results in Dry::Configurable::AlreadyDefinedConfig errors when we
          # try and add more settings later
          # @_configuration = Hanami::Configuration.new(env: app_class.config.env)

          # Hard-code this for now, just to get out of the situation
          @_configuration = Hanami::Configuration.new(env: :development)

          extend ClassMethods
          # include InstanceMethods
        end

        Hanami.application = app_class
      end

      app_class.after :configure do
        register_inflector
        load_paths! "lib"
      end
    end

    def self.slices
      @slices ||= load_slices
    end

    def self.load_slices
      @slices ||= slice_paths
        .map(&method(:load_slice))
        .compact
        .to_h
    end

    # We can't call this `.boot` because it is the name used for registering
    # bootable components (I plan to change this)
    def self.boot!
      return self if booted?

      finalize! freeze: false

      load_slices
      slices.values.each(&:boot!)

      @booted = true

      freeze
      self
    end

    def self.booted?
      @booted.equal?(true)
    end

    MODULE_DELIMITER = "::"

    def self.module
      inflector.constantize(name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER))
    end

    private

    def self.slice_paths
      Dir[File.join(config.root, config.slices_dir, "*")]
    end

    def self.load_slice(base_path)
      base_path = Pathname(base_path)
      full_defn_path = Dir["#{base_path}/system/**/slice.rb"].first

      return unless full_defn_path

      require full_defn_path

      const_path = Pathname(full_defn_path)
        .relative_path_from(base_path.join("system")).to_s
        .yield_self { |path| path.sub(/#{File.extname(path)}$/, "") }

      const = inflector.constantize(inflector.camelize(const_path))

      [File.basename(base_path).to_sym, const]
    end

    def self.register_inflector
      return self if key?(:inflector)
      register :inflector, inflector
    end
  end
end
