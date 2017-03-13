require 'rack'

module Hanami
  # Rack compatible server.
  #
  # It is run with:
  #
  #   `bundle exec hanami server`
  #
  # It runs the application, by using the server specified in your `Gemfile`
  # (eg. Puma or Unicorn).
  #
  # @since 0.8.0
  # @api private
  class Server < ::Rack::Server
    # @api private
    attr_reader :options

    # @since 0.8.0
    # @api private
    #
    # @see Hanami::Environment#initialize
    def initialize
      @options = _extract_options
      setup
    end

    # Primarily this removes the ::Rack::Chunked middleware
    # which is the cause of Safari content-length bugs.
    #
    # @since 0.8.0
    def middleware
      mw = Hash.new { |e, m| e[m] = [] }
      mw["development"].concat([::Rack::ShowExceptions, ::Rack::Lint])
      require 'hanami/assets/static'
      mw["development"].push(::Hanami::Assets::Static)
      mw
    end

    # @api private
    def start
      preload
      super
    end

    private

    # @api private
    def setup
      return unless code_reloading?
      @app = Shotgun::Loader.new(rackup)
    end

    # @api private
    def environment
      Components['environment']
    end

    # @since 0.8.0
    # @api private
    def code_reloading?
      Hanami.code_reloading?
    end

    # @api private
    def rackup
      environment.rackup.to_s
    end

    # @api private
    def preload
      if code_reloading?
        Shotgun.enable_copy_on_write
        Shotgun.preload
      else
        Hanami.boot
      end
    end

    # Options for Rack::Server superclass
    #
    # @since 0.8.0
    # @api private
    def _extract_options
      environment.to_options.merge(
        config:      rackup,
        Host:        environment.host,
        Port:        environment.port,
        AccessLog:   []
      )
    end
  end
end
