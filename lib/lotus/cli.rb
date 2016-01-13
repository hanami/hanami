require 'thor'
require 'lotus/commands/console'
require 'lotus/commands/new/app'
require 'lotus/commands/new/container'

module Lotus
  class Cli < Thor
    # include Thor::Actions

    desc 'version', 'prints Lotus version'
    long_desc <<-EOS
    `lotus version` prints the version of the bundled lotus gem.
    EOS
    def version
      require 'lotus/version'
      puts "v#{ Lotus::VERSION }"
    end

    desc 'server', 'starts a lotus server'
    long_desc <<-EOS
    `lotus server` starts a server for the current lotus project.

    $ > lotus server

    $ > lotus server -p 4500
    EOS
    method_option :port, aliases: '-p', desc: 'The port to run the server on, '
    method_option :server, desc: 'choose a specific Rack::Handler, e.g. webrick, thin etc'
    method_option :rackup, desc: 'a rackup configuration file path to load (config.ru)'
    method_option :host, desc: 'the host address to bind to'
    method_option :debug, desc: 'turn on debug output'
    method_option :warn, desc: 'turn on warnings'
    method_option :daemonize, desc: 'if true, the server will daemonize itself (fork, detach, etc)'
    method_option :pid, desc: 'path to write a pid file after daemonize'
    method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
    method_option :code_reloading, desc: 'code reloading', type: :boolean, default: true
    method_option :help, desc: 'displays the usage message'
    def server
      if options[:help]
        invoke :help, ['server']
      else
        require 'lotus/commands/server'
        Lotus::Commands::Server.new(options).start
      end
    end

    desc 'console', 'starts a lotus console'
    long_desc <<-EOS
    `lotus console` starts the interactive lotus console.

    $ > lotus console --engine=pry
    EOS
    method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
    method_option :engine, desc: "choose a specific console engine: (#{Lotus::Commands::Console::ENGINES.keys.join('/')})", default: Lotus::Commands::Console::DEFAULT_ENGINE
    method_option :help, desc: 'displays the usage method'
    def console
      if options[:help]
        invoke :help, ['console']
      else
        Lotus::Commands::Console.new(options).start
      end
    end

    desc 'new APPLICATION_NAME', 'generate a new lotus project'
    long_desc <<-EOS
      `lotus new` creates a new lotus project.
      You can specify various options such as the database to be used as well as the path and architecture.

      $ > lotus new fancy_app --application_name=admin

      $ > lotus new fancy_app --arch=app

      $ > lotus new fancy_app --lotus-head=true
    EOS
    method_option :database, aliases: ['-d', '--db'], desc: "application database (#{Lotus::Generators::DatabaseConfig::SUPPORTED_ENGINES.keys.join('/')})", default: Lotus::Generators::DatabaseConfig::DEFAULT_ENGINE
    method_option :architecture, aliases: ['-a', '--arch'], desc: 'project architecture (container/app)', default: Lotus::Commands::New::Abstract::DEFAULT_ARCHITECTURE
    method_option :application_name, desc: 'application name, only for container', default: Lotus::Commands::New::Container::DEFAULT_APPLICATION_NAME
    method_option :application_base_url, desc: 'application base url', default: Lotus::Commands::New::Abstract::DEFAULT_APPLICATION_BASE_URL
    method_option :test, desc: "project test framework (#{Lotus::Generators::TestFramework::VALID_FRAMEWORKS.join('/')})", default: Lotus::Lotusrc::DEFAULT_TEST_SUITE
    method_option :lotus_head, desc: 'use Lotus HEAD (true/false)', type: :boolean, default: false
    method_option :help, desc: 'displays the usage method'
    def new(application_name)
      if options[:help]
        invoke :help, ['new']
      elsif options[:architecture] == 'app'
        Lotus::Commands::New::App.new(options, application_name).start
      else
        Lotus::Commands::New::Container.new(options, application_name).start
      end
    end

    desc 'routes', 'prints the routes'
    long_desc <<-EOS
      `lotus routes` outputs all the registered routes to the console.
    EOS
    method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
    method_option :help, desc: 'displays the usage method'
    def routes
      if options[:help]
        invoke :help, ['routes']
      else
        require 'lotus/commands/routes'
        Lotus::Commands::Routes.new(options).start
      end
    end

    desc 'runner [FILE|EXPRESSION]', 'Evaluate a file or expression with the preloaded environment and application'
    long_desc <<-EOS
      `lotus runner` Evaluate a file or expression with the preloaded environment and application.

      $ > lotus runner `puts Lotus.env` => The current environment

      $ > lotus runner ./my_script.rb => Loads the file.
    EOS
    method_option :help, desc: 'displays the usage method'
    def runner(expression_or_file)
      if options[:help]
        invoke :help, ['runner']
      else
        require 'lotus/commands/runner'
        Lotus::Commands::Runner.new(options, expression_or_file).start
      end
    end

    require 'lotus/cli_sub_commands/db'
    register Lotus::CliSubCommands::DB, 'db', 'db [SUBCOMMAND]', 'manage set of DB operations'

    require 'lotus/cli_sub_commands/generate'
    register Lotus::CliSubCommands::Generate, 'generate', 'generate [SUBCOMMAND]', 'generate lotus classes'

    require 'lotus/cli_sub_commands/destroy'
    register Lotus::CliSubCommands::Destroy, 'destroy', 'destroy [SUBCOMMAND]', 'destroy lotus classes'

    require 'lotus/cli_sub_commands/assets'
    register Lotus::CliSubCommands::Assets, 'assets', 'assets [SUBCOMMAND]', 'manage assets'
  end
end
