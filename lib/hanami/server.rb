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

    attr_reader :options

    # @param options [Hash] Environment's options
    #
    # @since 0.8.0
    # @see Hanami::Environment#initialize
    def initialize(options)
      @_env    = Hanami::Environment.new(options)
      @options = _extract_options
    end


    # @since 0.8.0
    # @api private
    def rackup_config
      @_env.rackup.to_s
    end


    # Adds Shotgun Loader
    #
    # @since 0.8.0
    # @api private
    def app=(shotgun_loader)
      @app = shotgun_loader
    end

    # Primarily this removes the ::Rack::Chunked middleware
    # which is the cause of Safari content-length bugs.
    #
    # @since 0.8.0
    def middleware
      mw = Hash.new { |e, m| e[m] = [] }
      mw["deployment"].concat([::Rack::ContentLength, ::Rack::CommonLogger])
      mw["development"].concat(mw["deployment"] + [::Rack::ShowExceptions, ::Rack::Lint])
      mw["development"].push(::Shotgun::Static) if enable_shotgun_static?
      mw
    end

    private

    # @since x.x.x
    # @api private
    def enable_shotgun_static?
      code_reloading? && shotgun_available?
    end

    # @since x.x.x
    # @api private
    def shotgun_available?
      require 'shotgun'
      true
    rescue LoadError
      false
    end

    # @since x.x.x
    # @api private
    def code_reloading?
      @_env.code_reloading?
    end

    # @since 0.8.0
    # @api private
    def _extract_options
      @_env.to_options.merge(
        config:      @_env.rackup.to_s,
        Host:        @_env.host,
        Port:        @_env.port,
        AccessLog:   []
      )
    end
  end
end
