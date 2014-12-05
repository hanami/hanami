require 'rack'
require 'shotgun'

module Lotus
  module Commands
    # Rack compatible server.
    #
    # It implements code reloading via process fork.
    # It loads a middleware stack that targets the development phase.
    #
    # For those reasons it SHOULD NOT be used for deployment purposes.
    #
    # @since 0.1.0
    # @api private
    class Server < ::Rack::Server
      attr_reader :options

      def initialize(env)
        @options = _extract_options(env)
        @app     = Shotgun::Loader.new(env.config, &_environment_middleware)
      end

      def start
        Shotgun.enable_copy_on_write
        Shotgun.preload
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

      def _environment_middleware
        Proc.new {
          use ::Rack::ContentLength
          use ::Rack::CommonLogger
          use ::Rack::ShowExceptions
          use ::Rack::Lint
        }
      end
    end
  end
end
