require 'rack'

module Hanami
  module Commands
    # Rack compatible server.
    #
    # It is run with:
    #
    #   `bundle exec hanami server`
    #
    # It runs the application, by using the server specified in your `Gemfile`
    # (eg. Puma or Unicorn).
    #
    # It enables code reloading by default.
    # This feature is implemented via process fork and requires `shotgun` gem.
    #
    # @since 0.1.0
    # @api private
    class Server < ::Rack::Server
      attr_reader :options

      # @param options [Hash] Environment's options
      #
      # @since 0.1.0
      # @see Hanami::Environment#initialize
      def initialize(options)
        @_env    = Hanami::Environment.new(options)
        @options = _extract_options(@_env)

        if code_reloading?
          require 'shotgun'
          @app = Shotgun::Loader.new(@_env.rackup.to_s)
        end
      end

      # Primarily this removes the ::Rack::Chunked middleware
      # which is the cause of Safari content-length bugs.
      #
      # @since 0.1.0
      def middleware
        mw = Hash.new { |e, m| e[m] = [] }
        mw["deployment"].concat([::Rack::ContentLength, ::Rack::CommonLogger])
        mw["development"].concat(mw["deployment"] + [::Rack::ShowExceptions, ::Rack::Lint])
        mw
      end

      # Kickstart shotgun preloader if code reloading is supported
      #
      # @since 0.1.0
      def start
        if code_reloading?
          Shotgun.enable_copy_on_write
          Shotgun.preload
        end

        super
      end

      private

      # @since 0.1.0
      # @api private
      def _extract_options(env)
        env.to_options.merge(
          config:      env.rackup.to_s,
          Host:        env.host,
          Port:        env.port,
          AccessLog:   []
        )
      end

      # @since 0.1.0
      # @api private
      def code_reloading?
        @_env.code_reloading?
      end
    end
  end
end
