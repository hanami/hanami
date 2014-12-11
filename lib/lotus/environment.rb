require 'thread'
require 'lotus/utils/hash'

module Lotus
  # Define and expose information about the Lotus environment.
  #
  # @since 0.1.0
  class Environment
    RACK_ENV    = 'RACK_ENV'.freeze
    LOTUS_ENV   = 'LOTUS_ENV'.freeze
    DEFAULT_ENV = 'development'.freeze

    LOTUS_HOST      = 'LOTUS_HOST'.freeze
    DEFAULT_HOST    = 'localhost'.freeze
    LISTEN_ALL_HOST = '0.0.0.0'.freeze

    LOTUS_PORT   = 'LOTUS_PORT'.freeze
    DEFAULT_PORT = 2300

    DEFAULT_CONFIG       = 'config.ru'.freeze
    DEFAULT_APPLICATIONS = 'config/applications'.freeze

    CODE_RELOADING = { 'development' => true }

    # @param options [Hash] override default options for various environment attributes
    def initialize(options = {})
      @options = Utils::Hash.new(options).symbolize!.freeze
      @mutex   = Mutex.new
      @mutex.synchronize { set_env_vars! }
    end

    # In what context are the applications running?
    #
    # @return [String]
    def environment
      @environment ||= ENV[LOTUS_ENV] || ENV[RACK_ENV] || DEFAULT_ENV
    end

    # The HTTP host name
    #
    # @return [String]
    def host
      @host ||= @options.fetch(:host) {
        ENV[LOTUS_HOST] || default_host
      }
    end

    # The HTTP port
    #
    # @return [Integer]
    def port
      @port ||= @options.fetch(:port) { ENV[LOTUS_PORT] || DEFAULT_PORT }.to_i
    end

    # Filename of the Rack configuration file
    #
    # @return [String] filename with the Rack configuration
    def config
      @options.fetch(:config) { DEFAULT_CONFIG }
    end

    # @return [String] path to directory that contains registered applications
    def applications
      @options.fetch(:applications) { DEFAULT_APPLICATIONS }
    end

    # @return [TrueClass,FalseClass]
    def code_reloading?
      @options.fetch(:code_reloading) { !!CODE_RELOADING[environment] }
    end

    # @return [Lotus::Utils::Hash]
    def to_options
      @options.merge(
        environment:  environment,
        applications: applications,
        config:       config,
        host:         host,
        port:         port
      )
    end

    private
    def set_env_vars!
      ENV[LOTUS_ENV]  = ENV[RACK_ENV] = environment
      ENV[LOTUS_HOST] = host
      ENV[LOTUS_PORT] = port.to_s
    end

    def default_host
      environment == DEFAULT_ENV ? DEFAULT_HOST : LISTEN_ALL_HOST
    end
  end
end
