require 'thread'
require 'pathname'
require 'hanami/utils'
require 'hanami/utils/hash'
require 'hanami/hanamirc'
begin
  require 'dotenv'
rescue LoadError
end

module Hanami
  # Define and expose information about the Hanami environment.
  #
  # @since 0.1.0
  # @api private
  class Environment
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
    CONTAINER = 'container'.freeze

    # @since 0.4.0
    # @api private
    CONTAINER_PATH = 'apps'.freeze

    # @since 0.4.0
    # @api private
    APPLICATION = 'app'.freeze

    # @since 0.4.0
    # @api private
    APPLICATION_PATH = 'app'.freeze

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
    # It also evaluates configuration from `.env` and `.env.<environment>`
    # located under the config directory. All the settings in those files will
    # be exported as `ENV` variables.
    #
    # The format of those `.env` files is compatible with `dotenv` and `foreman`
    # gems.
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
    # @example Define ENV variables from .env
    #
    #   # % tree .
    #   #   .
    #   #   # ...
    #   #   ├── .env
    #   #   └── .env.development
    #
    #   # % cat .env
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
    #   ENV['XYZ']        # => "yes"
    #
    #   # Hanami::Environment evaluates `.env` first as master configuration.
    #   # Then it evaluates `.env.development` because the current environment
    #   # is "development". The settings defined in this last file override
    #   # the one defined in the parent (eg `FOO` is overwritten). All the
    #   # other settings (eg `XYZ`) will be left untouched.
    def initialize(options = {})
      @options = Hanami::Hanamirc.new(root).options
      @options.merge! Utils::Hash.new(options.clone).symbolize!
      @mutex   = Mutex.new
      @mutex.synchronize { set_env_vars! }
    end

    # The current environment
    #
    # In order to decide the value, it looks up to the following `ENV` vars:
    #
    #   * HANAMI_ENV
    #   * RACK_ENV
    #
    # If those are missing it falls back to the defalt one: `"development"`.
    #
    # Rack environment `"deployment"` is translated to Hanami `"production"`.
    #
    # @return [String] the current environment
    #
    # @since 0.1.0
    #
    # @see Hanami::Environment::DEFAULT_ENV
    def environment
      @environment ||= ENV[HANAMI_ENV] || rack_env || DEFAULT_ENV
    end

    # @since 0.3.1
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

    # Application's root
    #
    # It defaults to the current working directory.
    # Hanami assumes that all the commands are executed from there.
    #
    # @return [Pathname] application's root
    #
    # @since 0.2.0
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
    #
    # @see Hanami::Environment::DEFAULT_HOST
    # @see Hanami::Environment::LISTEN_ALL_HOST
    def host
      @host ||= @options.fetch(:host) {
        ENV[HANAMI_HOST] || default_host
      }
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
    #
    # @see Hanami::Environment::DEFAULT_PORT
    def port
      @port ||= @options.fetch(:port) { ENV[HANAMI_PORT] || DEFAULT_PORT }.to_i
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
    #
    # @see Hanami::Environment::DEFAULT_ENVIRONMENT_CONFIG
    def env_config
      root.join(@options.fetch(:environment) { config.join(DEFAULT_ENVIRONMENT_CONFIG) })
    end

    # Require application environment
    #
    # Eg <tt>require "config/environment"</tt>.
    #
    # @since 0.4.0
    # @api private
    def require_application_environment
      require env_config.to_s
    end

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
    #
    # @see Hanami::Commands::Server
    # @see Hanami::Environment::CODE_RELOADING
    def code_reloading?
      @options.fetch(:code_reloading) { !!CODE_RELOADING[environment] }
    end

    # @since 0.4.0
    # @api private
    def architecture
      @options.fetch(:architecture) {
        puts "Cannot recognize Hanami architecture, please check `.hanamirc'"
        exit 1
      }
    end

    # @since 0.4.0
    # @api private
    def container?
      architecture == CONTAINER
    end

    # @since 0.6.0
    # @api private
    def serve_static_assets?
      SERVE_STATIC_ASSETS_ENABLED == ENV[SERVE_STATIC_ASSETS]
    end

    # @since 0.4.0
    # @api private
    def apps_path
      @options.fetch(:path) {
        case architecture
        when CONTAINER   then CONTAINER_PATH
        when APPLICATION then APPLICATION_PATH
        end
      }
    end

    # Serialize the most relevant settings into a Hash
    #
    # @return [Hanami::Utils::Hash]
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

    # @since 0.1.0
    # @api private
    def set_env_vars!
      set_application_env_vars!
      set_hanami_env_vars!
    end

    # @since 0.2.0
    # @api private
    def set_hanami_env_vars!
      ENV[HANAMI_ENV]  = ENV[RACK_ENV] = environment
      ENV[HANAMI_HOST] = host
      ENV[HANAMI_PORT] = port.to_s
    end

    # @since 0.2.0
    # @api private
    def set_application_env_vars!
      return unless defined?(Dotenv) && (dotenv = root.join(DEFAULT_DOTENV_ENV % environment)).exist?
      Dotenv.overload dotenv
    end

    # @since 0.1.0
    # @api private
    def default_host
      environment == DEFAULT_ENV ? DEFAULT_HOST : LISTEN_ALL_HOST
    end

    # @since 0.6.0
    # @api private
    def rack_env
      case ENV[RACK_ENV]
      when RACK_ENV_DEPLOYMENT
        PRODUCTION_ENV
      else
        ENV[RACK_ENV]
      end
    end
  end
end
