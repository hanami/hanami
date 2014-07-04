require 'thread'
require 'lotus/utils/hash'

module Lotus
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

    def initialize(options = {})
      @options = Utils::Hash.new(options).symbolize!.freeze
      @mutex   = Mutex.new
      @mutex.synchronize { set_env_vars! }
    end

    def environment
      @environment ||= ENV[LOTUS_ENV] || ENV[RACK_ENV] || DEFAULT_ENV
    end

    def host
      @host ||= @options.fetch(:host) {
        ENV[LOTUS_HOST] || default_host
      }
    end

    def port
      @port ||= @options.fetch(:port) { ENV[LOTUS_PORT] || DEFAULT_PORT }.to_i
    end

    def config
      @options.fetch(:config) { DEFAULT_CONFIG }
    end

    def applications
      @options.fetch(:applications) { DEFAULT_APPLICATIONS }
    end

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
