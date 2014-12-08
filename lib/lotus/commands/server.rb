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

      def middleware
        @middleware ||= Hash.new {|h,k| h[k] = []}
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
