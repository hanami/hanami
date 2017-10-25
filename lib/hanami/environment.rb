require 'thread'
require 'pathname'
require 'hanami/utils'
require 'hanami/utils/hash'
require 'hanami/env'
require 'hanami/hanamirc'
require 'hanami/components'

module Hanami
  # Define and expose information about the Hanami environment.
  #
  # @since 0.1.0
  # @api private
  class Environment
    # Global lock (used to serialize process of environment configuration)
    #
    # @since 0.8.0
    # @api private
    LOCK = Mutex.new

    # Standard Rack ENV key
    #
    # @since 0.1.0
    # @api private
    RACK_ENV       = 'RACK_ENV'.freeze

    # Standard Hanami ENV key
    #
    # @since 0.1.0
    # @api private
    HANAMI_ENV      = 'HANAMI_ENV'.freeze

    # Default Hanami environment
    #
    # @since 0.1.0
    # @api private
    DEFAULT_ENV    = 'development'.freeze

    # Production environment
    #
    # @since 0.6.0
    # @api private
    PRODUCTION_ENV = 'production'.freeze

    # Rack production environment (aka deployment)
    #
    # @since 0.6.0
    # @api private
    RACK_ENV_DEPLOYMENT = 'deployment'.freeze

    # Default `.env` per environment file name
    #
    # @since 0.2.0
    # @api private
    DEFAULT_DOTENV_ENV = '.env.%s'.freeze

    # Default configuration directory under application root
    #
    # @since 0.2.0
    # @api private
    DEFAULT_CONFIG = 'config'.freeze

    # Standard Hanami host ENV key
    #
    # @since 0.1.0
    # @api private
    HANAMI_HOST      = 'HANAMI_HOST'.freeze

    # Default HTTP host
    #
    # @since 0.1.0
    # @api private
    DEFAULT_HOST    = 'localhost'.freeze

    # Default IP address listen
    #
    # @since 0.1.0
    # @api private
    LISTEN_ALL_HOST = '0.0.0.0'.freeze

    # Standard Hanami port ENV key
    #
    # @since 0.1.0
    # @api private
    HANAMI_PORT   = 'HANAMI_PORT'.freeze

    # Default Hanami HTTP port
    #
    # @since 0.1.0
    # @api private
    DEFAULT_PORT = 2300

    # Default Rack configuration file
    #
    # @since 0.2.0
    # @api private
    DEFAULT_RACKUP       = 'config.ru'.freeze

    # Default environment configuration file
    #
    # @since 0.2.0
    # @api private
    DEFAULT_ENVIRONMENT_CONFIG = 'environment'.freeze

    # Code reloading per environment
    #
    # @since 0.2.0
    # @api private
    CODE_RELOADING = { 'development' => true }.freeze

    # @since 0.4.0
    # @api private
    APPS_PATH = 'apps'.freeze

    # @since 0.4.0
    # @api private
    SERVE_STATIC_ASSETS = 'SERVE_STATIC_ASSETS'.freeze

    # @since 0.4.0
    # @api private
    SERVE_STATIC_ASSETS_ENABLED = 'true'.freeze

    # Initialize a Hanami environment
    #
    # It accepts an optional set of configurations from the CLI commands.
    # Those settings override the defaults defined by this object.
    #
    # When initialized, it sets standard `ENV` variables for Rack and Hanami,
    # such as `RACK_ENV` and `HANAMI_ENV`.
    #
    # It evaluates configuration ONLY from `.env.<environment>` file
    # located under the config directory. All the settings in those files will
    # be exported as `ENV` variables.
    #
    # Master .env file is ignored to suggest clear separation of environment
    # configurations and discourage putting sensitive information into source
    # control.
    #
    # The format of those `.env.<environment>` files follows UNIX and UNIX-like
    # operating system environment variable declaration format and compatible
    # with `dotenv` and `foreman` gems.
    #
    # @param options [Hash] override default options for various environment
    #   attributes
    #
    # @return [Hanami::Environment] the environment
    #
    # @see Hanami::Commands::Console
    # @see Hanami::Commands::Routes
    # @see Hanami::Commands::Server
    # @see Hanami::Environment#config
    #
    # @api private
    #
    # @example Define ENV variables from .env
    #
    #   # % tree .
    #   #   .
    #   #   # ...
    #   #   ├── .env.test
    #   #   └── .env.development
    #
    #   # % cat .env.test
    #   #   FOO="bar"
    #   #   XYZ="yes"
    #
    #   # % cat .env.development
    #   #   FOO="ok"
    #
    #   require 'hanami/environment'
    #
    #   env = Hanami::Environment.new
    #   env.environment   # => "development"
    #
    #   # Framework defined ENV vars
    #   ENV['HANAMI_ENV']  # => "development"
    #   ENV['RACK_ENV']   # => "development"
    #
    #   ENV['HANAMI_HOST'] # => "localhost"
    #   ENV['HANAMI_PORT'] # => "2300"
    #
    #   # User defined ENV vars
    #   ENV['FOO']        # => "ok"
    #   ENV['XYZ']        # => nil
    #
    #   # Hanami::Environment evaluates `.env.development` because the current
    #   # environment is "development".
    #   # Variables declared on `.env.development` will not override
    #   # any variable declared on the shell when calling a `hanami` command.
    #   # Eg. In `FOO="not ok" bundle exec hanami c` `FOO` will not be overwritten
    #   # to `"ok"`.
    def initialize(options = {})
      opts     = options.to_h.dup
      @env     = Hanami::Env.new(env: opts.delete(:env) || ENV)
      @options = Hanami::Hanamirc.new(root).options
      @options.merge! Utils::Hash.symbolize(opts.clone)
      LOCK.synchronize { set_env_vars! }
    end

    # The current environment
    #
    # In order to decide the value, it looks up to the following `ENV` vars:
    #
    #   * HANAMI_ENV
    #   * RACK_ENV
    #
    # If those are missing it falls back to the default one: `"development"`.
    #
    # Rack environment `"deployment"` is translated to Hanami `"production"`.
    #
    # @return [String] the current environment
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Environment::DEFAULT_ENV
    def environment
      @environment ||= env[HANAMI_ENV] || rack_env || DEFAULT_ENV
    end

    # @since 0.3.1
    # @api private
    #
    # @see Hanami.env?(name)
    def environment?(*names)
      names.map(&:to_s).include?(environment)
    end

    # A set of Bundler groups
    #
    # @return [Array] A set of groups
    #
    # @since 0.2.0
    # @api private
    #
    # @see http://bundler.io/v1.7/groups.html
    def bundler_groups
      [:default, environment]
    end

    # Project name
    #
    # @return [String] Project name
    #
    # @since 0.8.0
    # @api private
    def project_name
      @options.fetch(:project)
    end

    # Application's root
    #
    # It defaults to the current working directory.
    # Hanami assumes that all the commands are executed from there.
    #
    # @return [Pathname] application's root
    #
    # @since 0.2.0
    # @api private
    def root
      @root ||= Pathname.new(Dir.pwd)
    end

    # Application's config directory
    #
    # It's the application where all the configurations are stored.
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `config`
    #
    # If those are missing it falls back to the default one: `"config/"`.
    #
    # When a relative path is given via CLI option, it assumes to be located
    # under application's root. If absolute path, it will be used as it is.
    #
    # @return [Pathname] the config directory
    #
    # @since 0.2.0
    # @api private
    #
    # @see Hanami::Environment::DEFAULT_CONFIG
    # @see Hanami::Environment#root
    def config
      @config ||= root.join(@options.fetch(:config) { DEFAULT_CONFIG })
    end

    # The HTTP host name
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `host`
    #   * HANAMI_HOST ENV var
    #
    # If those are missing it falls back to the following defaults:
    #
    #   * `"localhost"` for development
    #   * `"0.0.0.0"` for all the other environments
    #
    # @return [String] the HTTP host name
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Environment::DEFAULT_HOST
    # @see Hanami::Environment::LISTEN_ALL_HOST
    def host
      @host ||= @options.fetch(:host) do
        env[HANAMI_HOST] || default_host
      end
    end

    # The HTTP port
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `port`
    #   * HANAMI_PORT ENV var
    #
    # If those are missing it falls back to the default one: `2300`.
    #
    # @return [Integer] the default port
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Environment::DEFAULT_PORT
    def port
      @port ||= @options.fetch(:port) do
        env[HANAMI_PORT] || DEFAULT_PORT
      end.to_i
    end

    # Check if the current port is the default one
    #
    # @since 1.0.0
    # @api private
    #
    # @see Hanami::ApplicationConfiguration#port
    def default_port?
      port == DEFAULT_PORT
    end

    # Path to the Rack configuration file
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `rackup`
    #
    # If those are missing it falls back to the default one: `"config.ru"`.
    #
    # When a relative path is given via CLI option, it assumes to be located
    # under application's root. If absolute path, it will be used as it is.
    #
    # @return [Pathname] path to the Rack configuration file
    #
    # @since 0.2.0
    # @api private
    def rackup
      root.join(@options.fetch(:rackup) { DEFAULT_RACKUP })
    end

    # Path to environment configuration file.
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `environment`
    #
    # If those are missing it falls back to the default one:
    # `"config/environment.rb"`.
    #
    # When a relative path is given via CLI option, it assumes to be located
    # under application's root. If absolute path, it will be used as it is.
    #
    # @return [Pathname] path to applications
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Environment::DEFAULT_ENVIRONMENT_CONFIG
    def env_config
      root.join("config", "environment.rb")
    end

    alias project_environment_configuration env_config

    # Require application environment
    #
    # Eg <tt>require "config/environment"</tt>.
    #
    # @since 0.4.0
    # @api private
    def require_application_environment
      Bundler.setup(*bundler_groups)
      require project_environment_configuration.to_s # if project_environment_configuration.exist?
    end

    # @api private
    alias require_project_environment require_application_environment

    # Determine if activate code reloading for the current environment while
    # running the server.
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `code_reloading`
    #
    # If those are missing it falls back to the following defaults:
    #
    #   * true for development
    #   * false for all the other environments
    #
    # @return [TrueClass,FalseClass] the result of the check
    #
    # @since 0.2.0
    # @api private
    #
    # @see Hanami::Commands::Server
    # @see Hanami::Environment::CODE_RELOADING
    def code_reloading?
      @options.fetch(:code_reloading) { !!CODE_RELOADING[environment] }
    end

    # @since 0.6.0
    # @api private
    def serve_static_assets?
      SERVE_STATIC_ASSETS_ENABLED == env[SERVE_STATIC_ASSETS]
    end

    # @since 0.6.0
    # @api private
    def static_assets_middleware
      return unless serve_static_assets?

      if environment?(:development, :test)
        require 'hanami/assets/static'
        Hanami::Assets::Static
      else
        require 'hanami/static'
        Hanami::Static
      end
    end

    # @since 0.4.0
    # @api private
    def apps_path
      @options.fetch(:path, APPS_PATH)
    end

    # Serialize the most relevant settings into a Hash
    #
    # @return [::Hash]
    #
    # @since 0.1.0
    # @api private
    def to_options
      @options.merge(
        environment: environment,
        env_config:  env_config,
        apps_path:   apps_path,
        rackup:      rackup,
        host:        host,
        port:        port
      )
    end

    private

    # @api private
    attr_reader :env

    # @since 0.1.0
    # @api private
    def set_env_vars!
      set_application_env_vars!
      set_hanami_env_vars!
    end

    # @since 0.2.0
    # @api private
    def set_hanami_env_vars!
      env[HANAMI_ENV]  = env[RACK_ENV] = environment
      env[HANAMI_HOST] = host
      env[HANAMI_PORT] = port.to_s
    end

    # @since 0.2.0
    # @api private
    def set_application_env_vars!
      dotenv = root.join(DEFAULT_DOTENV_ENV % environment)
      return unless dotenv.exist?

      env.load!(dotenv)
    end

    # @since 0.1.0
    # @api private
    def default_host
      environment == DEFAULT_ENV ? DEFAULT_HOST : LISTEN_ALL_HOST
    end

    # @since 0.6.0
    # @api private
    def rack_env
      case env[RACK_ENV]
      when RACK_ENV_DEPLOYMENT
        PRODUCTION_ENV
      else
        env[RACK_ENV]
      end
    end
  end
end
