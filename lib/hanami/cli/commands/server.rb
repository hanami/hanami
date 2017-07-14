module Hanami
  module Cli
    module Commands
      class Server
        include Hanami::Cli::Command

        register 'server'

        desc 'Starts a hanami server'

        option :port, alias: '-p', desc: 'The port to run the server on'
        option :server, desc: 'Choose a specific Rack::Handler (webrick, thin, etc)'
        option :rackup, desc: 'A rackup configuration file path to load (config.ru)'
        option :host, desc: 'The host address to bind to'
        option :debug, desc: 'Turn on debug output'
        option :warn, desc: 'Turn on warnings'
        option :daemonize, desc: 'If true, the server will daemonize itself (fork, detach, etc)'
        option :pid, desc: 'Path to write a pid file after daemonize'
        option :environment, desc: 'Path to environment configuration (config/environment.rb)'
        option :code_reloading, desc: 'Code reloading', type: :boolean, default: true

        def call(options)
          require 'hanami/commands/server'
          Hanami::Commands::Server.new(options).start
        end
      end
    end
  end
end
