module Hanami
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class Server < Command
        requires 'code_reloading'

        desc "Start Hanami server (only for development)"

        option :server,         desc: "Force a server engine (eg, webrick, puma, thin, etc..)"
        option :host,           desc: "The host address to bind to"
        option :port,           desc: "The port to run the server on", aliases: ["-p"]
        option :debug,          desc: "Turn on debug output"
        option :warn,           desc: "Turn on warnings"
        option :daemonize,      desc: "Daemonize the server"
        option :pid,            desc: "Path to write a pid file after daemonize"
        option :code_reloading, desc: "Code reloading", type: :boolean, default: true

        example [
          "                    # Basic usage (it uses the bundled server engine)",
          "--server=webrick    # Force `webrick` server engine",
          "--host=0.0.0.0      # Bind to a host",
          "--port=2306         # Bind to a port",
          "--no-code-reloading # Disable code reloading"
        ]

        # @since 1.1.0
        # @api private
        def call(*)
          require "hanami/server"
          Hanami::Server.new.start
        end
      end
    end

    register "server", Commands::Server, aliases: ["s"]
  end
end
