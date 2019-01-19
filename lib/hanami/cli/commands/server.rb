# frozen_string_literal: true

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class Server < Command
        desc "Start Hanami server (only for development)"

        option :server,    desc: "Force a server engine (eg, webrick, puma, thin, etc..)"
        option :host,      desc: "The host address to bind to"
        option :port,      desc: "The port to run the server on", aliases: ["-p"]
        option :debug,     desc: "Turn on debug output", type: :boolean
        option :warn,      desc: "Turn on warnings", type: :boolean
        option :daemonize, desc: "Daemonize the server", type: :boolean
        option :pid,       desc: "Path to write a pid file after daemonize"

        example [
          "                    # Basic usage (it uses the bundled server engine)",
          "--server=webrick    # Force `webrick` server engine",
          "--host=0.0.0.0      # Bind to a host",
          "--port=2306         # Bind to a port"
        ]

        # @since 1.1.0
        # @api private
        def call(**args)
          require "hanami"
          require "hanami/container"
          require "hanami/server"

          options = parse_arguments(args)
          Hanami::Server.new(options).start
        end

        private

        DEFAULT_CONFIG = "config.ru"
        private_constant :DEFAULT_CONFIG

        DEFAULT_HOST = "0.0.0.0"
        private_constant :DEFAULT_HOST

        DEFAULT_PORT = "2300"
        private_constant :DEFAULT_PORT

        OPTIONAL_SETTINGS = %i[
          server
          debug
          warn
          daemonize
          pid
        ].freeze

        def parse_arguments(args)
          Hanami::Container.start(:env)

          {
            config: DEFAULT_CONFIG,
            Host: host(args),
            Port: port(args),
            AccessLog: []
          }.merge(
            args.slice(*OPTIONAL_SETTINGS)
          )
        end

        def host(args)
          args.fetch(:host) do
            ENV.fetch("HANAMI_HOST", DEFAULT_HOST)
          end
        end

        def port(args)
          args.fetch(:port) do
            ENV.fetch("HANAMI_PORT", DEFAULT_PORT)
          end
        end
      end
    end

    register "server", Commands::Server, aliases: ["s"]
  end
end
