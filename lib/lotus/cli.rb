require 'thor'
require 'lotus/environment'

module Lotus
  class Cli < Thor
    include Thor::Actions

    desc 'server', 'starts a lotus server'
    method_option :port,      aliases: '-p', desc: 'The port to run the server on, '
    method_option :server,                   desc: 'choose a specific Rack::Handler, e.g. webrick, thin etc'
    method_option :rackup,                   desc: 'a rackup configuration file path to load (config.ru)'
    method_option :host,                     desc: 'the host address to bind to'
    method_option :debug,                    desc: 'turn on debug output'
    method_option :warn,                     desc: 'turn on warnings'
    method_option :daemonize,                desc: 'if true, the server will daemonize itself (fork, detach, etc)'
    method_option :pid,                      desc: 'path to write a pid file after daemonize'
    method_option :environment,              desc: 'path to environment configuration (config/environment.rb)'
    method_option :code_reloading,           desc: 'code reloading', type: :boolean, default: true
    method_option :help,      aliases: '-h', desc: 'displays the usage message'

    def server
      if options[:help]
        invoke :help, ['server']
      else
        require 'lotus/commands/server'
        Lotus::Commands::Server.new(environment).start
      end
    end

    desc 'console', 'starts a lotus console'
    method_option :environment,           desc: 'path to environment configuration (config/environment.rb)'
    method_option :engine,                desc: 'choose a specific console engine: irb/pry/ripl (irb)'
    method_option :help,   aliases: '-h', desc: 'displays the usage method'

    def console
      if options[:help]
        invoke :help, ['console']
      else
        require 'lotus/commands/console'
        Lotus::Commands::Console.new(environment).start
      end
    end

    desc 'routes', 'prints routes'
    method_option :environment,                 desc: 'path to environment configuration (config/environment.rb)'
    method_option :help,         aliases: '-h', desc: 'displays the usage method'

    def routes
      if options[:help]
        invoke :help, ['routes']
      else
        require 'lotus/commands/routes'
        Lotus::Commands::Routes.new(environment).start
      end
    end

    desc 'new', 'generates a new application'
    method_option :architecture,   aliases: '-a', desc: 'application architecture', type: :string,  default: 'container'
    method_option :slice,                         desc: 'slice name',               type: :string,  default: 'web'
    method_option :slice_base_url,                desc: 'slice base url',           type: :string,  default: '/'
    method_option :lotus_head,                    desc: 'use Lotus HEAD',           type: :boolean, default: false
    method_option :help,           aliases: '-h', desc: 'displays the usage method'

    def new(name = nil)
      if options[:help]
        invoke :help, ['new']
      else
        require 'lotus/commands/new'
        Lotus::Commands::New.new(name, environment, self).start
      end
    end

    private

    def environment
      Lotus::Environment.new(options)
    end
  end
end
