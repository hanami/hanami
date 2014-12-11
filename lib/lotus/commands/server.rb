require 'rack'

module Lotus
  module Commands
    # Rack compatible server.
    #
    # It is run with:
    #
    #   `bundle exec lotus server`
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

      def initialize(env)
        @_env    = env
        @options = _extract_options(@_env)

        if code_reloading?
          require 'shotgun'
          @app = Shotgun::Loader.new(@_env.config)
        end
      end

      # Primarily this removes the ::Rack::Chunked middleware
      # which is the cause of Safari content-length bugs.
      def middleware
        mw = Hash.new { |e, m| e[m] = [] }
        mw["deployment"].concat([::Rack::ContentLength, ::Rack::CommonLogger])
        mw["development"].concat(mw["deployment"] + [::Rack::ShowExceptions, ::Rack::Lint])
        mw
      end

      def start
        if code_reloading?
          Shotgun.enable_copy_on_write
          Shotgun.preload
        end

        super
      end

      private
      def _extract_options(env)
        env.to_options.merge(
          Host:        env.host,
          Port:        env.port,
          AccessLog:   []
        )
      end

      def code_reloading?
        @_env.code_reloading?
      end
    end
  end
end
