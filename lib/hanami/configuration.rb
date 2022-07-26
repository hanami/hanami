# frozen_string_literal: true

require "uri"
require "concurrent/hash"
require "concurrent/array"
require "dry/configurable"
require "dry/inflector"
require "pathname"

require_relative "constants"
require_relative "configuration/logger"
require_relative "configuration/router"
require_relative "configuration/sessions"
require_relative "settings/env_store"
require_relative "slice/routing/middleware/stack"

module Hanami
  # Hanami app configuration
  #
  # @since 2.0.0
  class Configuration
    include Dry::Configurable

    setting :root, constructor: ->(path) { Pathname(path) if path }

    setting :no_auto_register_paths, default: %w[entities]

    setting :inflector, default: Dry::Inflector.new

    setting :settings_store, default: Hanami::Settings::EnvStore.new

    setting :slices do
      setting :load_slices
      setting :skip_slices

      setting :shared_app_component_keys, default: %w[
        inflector
        logger
        notifications
        rack.monitor
        routes
        settings
      ]
    end

    setting :base_url, default: "http://0.0.0.0:2300", constructor: ->(url) { URI(url) }

    setting :sessions, default: :null, constructor: ->(*args) { Sessions.new(*args) }

    setting :logger, cloneable: true

    DEFAULT_ENVIRONMENTS = Concurrent::Hash.new { |h, k| h[k] = Concurrent::Array.new }
    private_constant :DEFAULT_ENVIRONMENTS

    # @return [Symbol] The name of the application
    #
    # @api public
    attr_reader :app_name

    # @return [String] The current environment
    #
    # @api public
    attr_reader :env

    # @return [Hanami::Configuration::Actions]
    #
    # @api public
    attr_reader :actions

    # @return [Hanami::Slice::Routing::Middleware::Stack]
    #
    # @api public
    attr_reader :middleware

    # @api private
    alias_method :middleware_stack, :middleware

    # @return [Hanami::Configuration::Router]
    #
    # @api public
    attr_reader :router

    # @return [Hanami::Configuration::Views]
    #
    # @api public
    attr_reader :views

    # @return [Hanami::Assets::AppConfiguration]
    #
    # @api public
    attr_reader :assets

    # @return [Concurrent::Hash] A hash of default environments
    #
    # @api private
    attr_reader :environments
    private :environments

    # @api private
    def initialize(app_name:, env:)
      @app_name = app_name

      @environments = DEFAULT_ENVIRONMENTS.clone
      @env = env

      # Apply default values that are only knowable at initialize-time (vs require-time)
      self.root = Dir.pwd
      load_from_env

      config.logger = Configuration::Logger.new(env: env, app_name: app_name)

      @assets = load_dependent_config("hanami/assets/app_configuration") {
        Hanami::Assets::AppConfiguration.new
      }

      @actions = load_dependent_config("hanami/action") {
        require_relative "configuration/actions"
        Actions.new
      }

      @middleware = Slice::Routing::Middleware::Stack.new

      @router = Router.new(self)

      @views = load_dependent_config("hanami/view") {
        require_relative "configuration/views"
        Views.new
      }

      yield self if block_given?
    end

    # Apply configuration for the given environment
    #
    # @param env [String] the environment name
    #
    # @return [Hanami::Configuration]
    #
    # @api public
    def environment(env_name, &block)
      environments[env_name] << block
      apply_env_config

      self
    end

    # Configure application's inflections
    #
    # @see https://dry-rb.org/gems/dry-inflector
    #
    # @return [Dry::Inflector]
    #
    # @api public
    def inflections(&block)
      self.inflector = Dry::Inflector.new(&block)
    end

    # @api private
    def initialize_copy(source)
      super

      @app_name = app_name.dup
      @environments = environments.dup

      @assets = source.assets.dup
      @actions = source.actions.dup
      @middleware = source.middleware.dup
      @router = source.router.dup.tap do |router|
        router.instance_variable_set(:@base_configuration, self)
      end
      @views = source.views.dup
    end

    # @api private
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

    # Set a default global logger instance
    #
    # @api public
    def logger=(logger_instance)
      @logger_instance = logger_instance
    end

    # Return configured logger instance
    #
    # @api public
    def logger_instance
      @logger_instance || logger.instance
    end

    private

    def load_from_env
      slices.load_slices = ENV["HANAMI_LOAD_SLICES"]&.split(",")&.map(&:strip)
      slices.skip_slices = ENV["HANAMI_SKIP_SLICES"]&.split(",")&.map(&:strip)
    end

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
