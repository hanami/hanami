# frozen_string_literal: true

require "uri"
require "concurrent/hash"
require "concurrent/array"
require "dry/configurable"
require "dry/inflector"
require "pathname"
require "zeitwerk"

require_relative "application/settings/dotenv_store"
require_relative "configuration/logger"
require_relative "configuration/middleware"
require_relative "configuration/router"
require_relative "configuration/sessions"

module Hanami
  # Hanami application configuration
  #
  # @since 2.0.0
  #
  # rubocop:disable Metrics/ClassLength
  class Configuration
    include Dry::Configurable

    DEFAULT_ENVIRONMENTS = Concurrent::Hash.new { |h, k| h[k] = Concurrent::Array.new }
    private_constant :DEFAULT_ENVIRONMENTS

    attr_reader :actions
    attr_reader :middleware
    attr_reader :router
    attr_reader :views

    attr_reader :environments
    private :environments

    def initialize(env:)
      @environments = DEFAULT_ENVIRONMENTS.clone
      config.env = env

      # Some default setting values must be assigned at initialize-time to ensure they
      # have appropriate values for the current application
      self.root = Dir.pwd
      self.autoloader = Zeitwerk::Loader.new

      # Config for actions (same for views, below) may not be available if the gem isn't
      # loaded; fall back to a null config object if it's missing
      @actions = begin
        require_path = "hanami/action/application_configuration"
        require require_path
        Hanami::Action::ApplicationConfiguration.new
      rescue LoadError => e
        raise e unless e.path == require_path
        require_relative "configuration/null_configuration"
        NullConfiguration.new
      end

      @middleware = Middleware.new

      @router = Router.new(self)

      @views = begin
        require_path = "hanami/view/application_configuration"
        require require_path
        Hanami::View::ApplicationConfiguration.new
      rescue LoadError => e
        raise e unless e.path == require_path
        require_relative "configuration/null_configuration"
        NullConfiguration.new
      end

      yield self if block_given?
    end

    def environment(env_name, &block)
      environments[env_name] << block
      apply_env_config

      self
    end

    def finalize!
      apply_env_config

      # Finalize nested configurations
      actions.finalize!
      views.finalize!
      logger.finalize!
      router.finalize!

      super
    end

    setting :env

    def env=(new_env)
      config.env = env
      apply_env_config(new_env)
    end

    setting :root do |path|
      Pathname(path)
    end

    setting :autoloader do |autoloader|
      # Convert all falsey values to nil, so we can rely on `nil` representing a disabled
      # autoloader when reading this setting
      autoloader || nil
    end

    setting :inflector, Dry::Inflector.new, cloneable: true

    def inflections(&block)
      self.inflector = Dry::Inflector.new(&block)
    end

    setting :logger, Configuration::Logger.new, cloneable: true

    def logger=(logger_instance)
      @logger_instance = logger_instance
    end

    def logger_instance
      @logger_instance || logger.logger_class.new(**logger.options)
    end

    setting :settings_path, File.join("config", "settings")

    setting :settings_class_name, "Settings"

    setting :settings_store, Application::Settings::DotenvStore.new.with_dotenv_loaded

    setting :slices_dir, "slices"

    setting :slices_namespace, Object

    # TODO: convert into a dedicated object with explicit behaviour around blocks per
    # slice, etc.
    setting :slices, {} do |value|
      value.dup
    end

    def slice(slice_name, &block)
      slices[slice_name] = block
    end

    setting :base_url, "http://0.0.0.0:2300" do |url|
      URI(url)
    end

    def for_each_middleware(&blk)
      stack = middleware.stack.dup
      stack += sessions.middleware if sessions.enabled?

      stack.each(&blk)
    end

    setting :sessions, :null do |*args|
      Sessions.new(*args)
    end

    private

    def apply_env_config(env = self.env)
      environments[env].each do |block|
        instance_eval(&block)
      end
    end

    def method_missing(name, *args, &block)
      if config.respond_to?(name)
        config.public_send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, _incude_all = false)
      config.respond_to?(name) || super
    end
  end
end
