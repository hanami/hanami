# frozen_string_literal: true

require "uri"
require "concurrent/hash"
require "concurrent/array"
require "dry/configurable"
require "dry/inflector"
require "pathname"

require_relative "settings/dotenv_store"
require_relative "configuration/logger"
require_relative "configuration/middleware"
require_relative "configuration/router"
require_relative "configuration/sessions"
require_relative "constants"

module Hanami
  # Hanami application configuration
  #
  # @since 2.0.0
  class Configuration
    include Dry::Configurable

    DEFAULT_ENVIRONMENTS = Concurrent::Hash.new { |h, k| h[k] = Concurrent::Array.new }
    private_constant :DEFAULT_ENVIRONMENTS

    attr_reader :application_name
    attr_reader :env

    attr_reader :actions
    attr_reader :middleware
    attr_reader :router
    attr_reader :views, :assets

    attr_reader :environments
    private :environments

    def initialize(application_name:, env:)
      @application_name = application_name

      @environments = DEFAULT_ENVIRONMENTS.clone
      @env = env

      # Some default setting values must be assigned at initialize-time to ensure they
      # have appropriate values for the current application
      self.root = Dir.pwd
      self.settings_store = Hanami::Settings::DotenvStore.new.with_dotenv_loaded

      config.logger = Configuration::Logger.new(env: env, application_name: application_name)

      @assets = load_dependent_config("hanami/assets/application_configuration") {
        Hanami::Assets::ApplicationConfiguration.new
      }

      @actions = load_dependent_config("hanami/action") {
        require_relative "configuration/actions"
        Actions.new
      }

      @middleware = Middleware.new

      @router = Router.new(self)

      @views = load_dependent_config("hanami/view") {
        require_relative "configuration/views"
        Views.new
      }

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
      assets.finalize!
      actions.finalize!
      views.finalize!
      logger.finalize!
      router.finalize!

      super
    end

    setting :root, constructor: -> path { Pathname(path) }

    setting :no_auto_register_paths, default: %w[entities]

    setting :inflector, default: Dry::Inflector.new

    def inflections(&block)
      self.inflector = Dry::Inflector.new(&block)
    end

    setting :logger, cloneable: true

    def logger=(logger_instance)
      @logger_instance = logger_instance
    end

    def logger_instance
      @logger_instance || logger.instance
    end

    setting :settings_path, default: File.join("config", "settings")

    setting :settings_class_name, default: "Settings"

    setting :settings_store, default: Hanami::Settings::DotenvStore

    setting :base_url, default: "http://0.0.0.0:2300", constructor: -> url { URI(url) }

    def for_each_middleware(&blk)
      stack = middleware.stack.dup
      stack += sessions.middleware if sessions.enabled?

      stack.each(&blk)
    end

    setting :sessions, default: :null, constructor: -> *args { Sessions.new(*args) }

    private

    def apply_env_config(env = self.env)
      environments[env].each do |block|
        instance_eval(&block)
      end
    end

    def load_dependent_config(require_path, &block)
      require require_path
      yield
    rescue LoadError => e
      raise e unless e.path == require_path

      require_relative "configuration/null_configuration"
      NullConfiguration.new
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
