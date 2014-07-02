require 'thor'
require 'lotus/environment'
require 'lotus/commands/server'
require 'lotus/commands/console'
require 'lotus/utils/hash'

module Lotus
  class Cli < Thor
    desc 'server', 'starts a lotus server'
    method_option :port,      aliases: '-p', desc: 'The port to run the server on, '
    method_option :server,                   desc: 'choose a specific Rack::Handler, e.g. webrick, thin etc'
    method_option :config,                   desc: 'a rackup configuration file path to load (config.ru)'
    method_option :host,                     desc: 'the host address to bind to'
    method_option :debug,                    desc: 'turn on debug output'
    method_option :warn,                     desc: 'turn on warnings'
    method_option :daemonize,                desc: 'if true, the server will daemonize itself (fork, detach, etc)'
    method_option :pid,                      desc: 'path to write a pid file after daemonize'
    method_option :help,      aliases: '-h', desc: 'displays the usage message'

    def server
      if options[:help]
        invoke :help, ['server']
      else
        Lotus::Commands::Server.new(environment).start
      end
    end

    desc "console", "starts a lotus console"
    method_option :applications,          desc: 'path to your applications.rb file (config/applications.rb)'
    method_option :help,   aliases: '-h', desc: 'displays the usage method'

    def console
      if options[:help]
        invoke :help, ['console']
      else
        Lotus::Commands::Console.new(symbolized_options).start
      end
    end

    private

    def environment
      Lotus::Environment.new(options)
    end


    def symbolized_options
      Lotus::Utils::Hash.new(options).symbolize!
    end
  end
end
