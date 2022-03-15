# frozen_string_literal: true

require "uri"
require "concurrent/hash"
require "concurrent/array"
require "dry/configurable"
require "dry/inflector"
require "pathname"

require_relative "application/settings/dotenv_store"
require_relative "configuration/logger"
require_relative "configuration/middleware"
require_relative "configuration/router"
require_relative "configuration/sessions"
require_relative "configuration/source_dirs"
require_relative "constants"

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

    attr_reader :env

    attr_reader :actions
    attr_reader :middleware
    attr_reader :router
    attr_reader :views, :assets

    attr_reader :environments
    private :environments

    def initialize(application_name:, env:)
      @namespace = application_name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER)

      @environments = DEFAULT_ENVIRONMENTS.clone
      @env = env

      # Some default setting values must be assigned at initialize-time to ensure they
      # have appropriate values for the current application
      self.root = Dir.pwd
      self.settings_store = Application::Settings::DotenvStore.new.with_dotenv_loaded

      config.logger = Configuration::Logger.new(env: env, application_name: method(:application_name))

      @assets = begin
        require_path = "hanami/assets/application_configuration"
        require require_path
        Hanami::Assets::ApplicationConfiguration.new
      rescue LoadError => e
        raise e unless e.path == require_path
        require_relative "configuration/null_configuration"
        NullConfiguration.new
      end

      @actions = load_dependent_config("hanami/action") {
        require_relative "configuration/actions"
        Actions.new
      }

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
      assets.finalize!
      actions.finalize!
      views.finalize!
      logger.finalize!
      router.finalize!

      super
    end

    def namespace
      inflector.constantize(@namespace)
    end

    def application_name
      inflector.underscore(@namespace).to_sym
    end

    setting :root, constructor: -> path { Pathname(path) }

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

    setting :settings_store, default: Application::Settings::DotenvStore

    setting :source_dirs, default: Configuration::SourceDirs.new, cloneable: true

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
