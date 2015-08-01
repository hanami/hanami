require 'thor'
require 'lotus/environment'
require 'lotus/version'

module Lotus
  class Cli < Thor
    include Thor::Actions

    desc 'version', 'prints Lotus version'
    def version
      puts "v#{ Lotus::VERSION }"
    end

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
    method_option :database,             aliases: ['-d', '--db'],   desc: 'application database (filesystem/memory/postgresql/sqlite3/mysql)', type: :string,  default: 'filesystem'
    method_option :architecture,         aliases: ['-a', '--arch'], desc: 'application architecture (container/app)', type: :string, default: 'container'
    method_option :application,                                     desc: 'application name',         type: :string,  default: 'web'
    method_option :application_base_url,                            desc: 'application base url',     type: :string,  default: '/'
    method_option :path,                                            desc: 'path',                     type: :string
    method_option :test,                                            desc: 'application test framework (rspec/minitest)', type: :string, default: 'minitest'
    method_option :lotus_head,                                      desc: 'use Lotus HEAD',           type: :boolean, default: false
    method_option :help,                 aliases: '-h',             desc: 'displays the usage method'

    def new(name = nil)
      if options[:help] || name.nil?
        invoke :help, ['new']
      else
        require 'lotus/commands/new'
        Lotus::Commands::New.new(name, environment, self).start
      end
    end

    desc 'generate', 'generates app, action, model or migration'
    method_option :application_base_url, desc: 'application base url',                                      type: :string
    method_option :path,                 desc: 'applications path',                                         type: :string
    method_option :url,                  desc: 'relative URL for action',                                   type: :string
    method_option :method,               desc: "HTTP method for action. Upper/lower case is ignored. Must be one of GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, TRACE.", type: :string, default: 'GET'
    method_option :skip_view,            desc: 'skip the creation of view and templates (only for action)', type: :boolean, default: false
    method_option :help, aliases: '-h',  desc: 'displays the usage method'

    # @since 0.3.0
    # @api private
    def generate(type = nil, app_name = nil, name = nil)
      if options[:help] || (type.nil? && app_name.nil? && name.nil?)
        invoke :help, ['generate']
      else
        require 'lotus/commands/generate'
        Lotus::Commands::Generate.new(type, app_name, name, environment, self).start
      end
    end

    require 'lotus/commands/db'
    register Lotus::Commands::DB, 'db', 'db [SUBCOMMAND]', 'manage set of DB operations'

    private

    def environment
      Lotus::Environment.new(options)
    end
  end
end
