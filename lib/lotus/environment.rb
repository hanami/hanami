require 'thread'
require 'pathname'
require 'dotenv'
require 'lotus/utils/hash'
require 'lotus/lotusrc'

module Lotus
  # Define and expose information about the Lotus environment.
  #
  # @since 0.1.0
  # @api private
  class Environment
    # Standard Rack ENV key
    #
    # @since 0.1.0
    # @api private
    RACK_ENV       = 'RACK_ENV'.freeze

    # Standard Lotus ENV key
    #
    # @since 0.1.0
    # @api private
    LOTUS_ENV      = 'LOTUS_ENV'.freeze

    # Default Lotus environment
    #
    # @since 0.1.0
    # @api private
    DEFAULT_ENV    = 'development'.freeze

    # Default `.env` file name
    #
    # @since 0.2.0
    # @api private
    DEFAULT_DOTENV = '.env'.freeze

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

    # Standard Lotus host ENV key
    #
    # @since 0.1.0
    # @api private
    LOTUS_HOST      = 'LOTUS_HOST'.freeze

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

    # Standard Lotus port ENV key
    #
    # @since 0.1.0
    # @api private
    LOTUS_PORT   = 'LOTUS_PORT'.freeze

    # Default Lotus HTTP port
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

    # Initialize a Lotus environment
    #
    # It accepts an optional set of configurations from the CLI commands.
    # Those settings override the defaults defined by this object.
    #
    # When initialized, it sets standard `ENV` variables for Rack and Lotus,
    # such as `RACK_ENV` and `LOTUS_ENV`.
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
    # @return [Lotus::Environment] the environment
    #
    # @see Lotus::Commands::Console
    # @see Lotus::Commands::Routes
    # @see Lotus::Commands::Server
    # @see Lotus::Environment#config
    #
    # @example Define ENV variables from .env
    #
    #   # % tree config/
    #   #   config
    #   #   ├── .env
    #   #   ├── .env.development
    #   #   └── environment.rb
    #
    #   # % cat config/.env
    #   #   FOO="bar"
    #   #   XYZ="yes"
    #
    #   # % cat config/.env.development
    #   #   FOO="ok"
    #
    #   require 'lotus/environment'
    #
    #   env = Lotus::Environment.new
    #   env.environment   # => "development"
    #
    #   # Framework defined ENV vars
    #   ENV['LOTUS_ENV']  # => "development"
    #   ENV['RACK_ENV']   # => "development"
    #
    #   ENV['LOTUS_HOST'] # => "localhost"
    #   ENV['LOTUS_PORT'] # => "2300"
    #
    #   # User defined ENV vars
    #   ENV['FOO']        # => "ok"
    #   ENV['XYZ']        # => "yes"
    #
    #   # Lotus::Environment evaluates `.env` first as master configuration.
    #   # Then it evaluates `.env.development` because the current environment
    #   # is "development". The settings defined in this last file override
    #   # the one defined in the parent (eg `FOO` is overwritten). All the
    #   # other settings (eg `XYZ`) will be left untouched.
    def initialize(options = {})
      @options = Lotus::Lotusrc.new(root).read
      @options.merge! Utils::Hash.new(options).symbolize!
      @mutex   = Mutex.new
      @mutex.synchronize { set_env_vars! }
    end

    # The current environment
    #
    # In order to decide the value, it looks up to the following `ENV` vars:
    #
    #   * LOTUS_ENV
    #   * RACK_ENV
    #
    # If those are missing it falls back to the defalt one: `"development"`.
    #
    # @return [String] the current environment
    #
    # @since 0.1.0
    #
    # @see Lotus::Environment::DEFAULT_ENV
    def environment
      @environment ||= ENV[LOTUS_ENV] || ENV[RACK_ENV] || DEFAULT_ENV
    end

    # @since x.x.x
    #
    # @see Lotus.env?(name)
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
      [environment]
    end

    # Application's root
    #
    # It defaults to the current working directory.
    # Lotus assumes that all the commands are executed from there.
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
    # @see Lotus::Environment::DEFAULT_CONFIG
    # @see Lotus::Environment#root
    def config
      @config ||= root.join(@options.fetch(:config) { DEFAULT_CONFIG })
    end

    # The HTTP host name
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `host`
    #   * LOTUS_HOST ENV var
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
    # @see Lotus::Environment::DEFAULT_HOST
    # @see Lotus::Environment::LISTEN_ALL_HOST
    def host
      @host ||= @options.fetch(:host) {
        ENV[LOTUS_HOST] || default_host
      }
    end

    # The HTTP port
    #
    # In order to decide the value, it looks up the following sources:
    #
    #   * CLI option `port`
    #   * LOTUS_PORT ENV var
    #
    # If those are missing it falls back to the default one: `2300`.
    #
    # @return [Integer] the default port
    #
    # @since 0.1.0
    #
    # @see Lotus::Environment::DEFAULT_PORT
    def port
      @port ||= @options.fetch(:port) { ENV[LOTUS_PORT] || DEFAULT_PORT }.to_i
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
    # @see Lotus::Environment::DEFAULT_ENVIRONMENT_CONFIG
    def env_config
      root.join(@options.fetch(:environment) { config.join(DEFAULT_ENVIRONMENT_CONFIG) })
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
    # @see Lotus::Commands::Server
    # @see Lotus::Environment::CODE_RELOADING
    def code_reloading?
      @options.fetch(:code_reloading) { !!CODE_RELOADING[environment] }
    end

    # Serialize the most relevant settings into a Hash
    #
    # @return [Lotus::Utils::Hash]
    #
    # @since 0.1.0
    # @api private
    def to_options
      @options.merge(
        environment: environment,
        env_config:  env_config,
        rackup:      rackup,
        host:        host,
        port:        port
      )
    end

    private

    # @since 0.1.0
    # @api private
    def set_env_vars!
      set_lotus_env_vars!
      set_application_env_vars!
    end

    # @since 0.2.0
    # @api private
    def set_lotus_env_vars!
      ENV[LOTUS_ENV]  = ENV[RACK_ENV] = environment
      ENV[LOTUS_HOST] = host
      ENV[LOTUS_PORT] = port.to_s
    end

    # @since 0.2.0
    # @api private
    def set_application_env_vars!
      Dotenv.load     config.join(DEFAULT_DOTENV)
      Dotenv.overload config.join(DEFAULT_DOTENV_ENV % environment)
    end

    # @since 0.1.0
    # @api private
    def default_host
      environment == DEFAULT_ENV ? DEFAULT_HOST : LISTEN_ALL_HOST
    end
  end
end
