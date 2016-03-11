require 'thor'
require 'hanami/commands/console'
require 'hanami/commands/new/app'
require 'hanami/commands/new/container'

module Hanami
  class Cli < Thor
    # include Thor::Actions

    desc 'version', 'Prints hanami version'
    long_desc <<-EOS
    `hanami version` prints the version of the bundled hanami gem.
    EOS
    def version
      require 'hanami/version'
      puts "v#{ Hanami::VERSION }"
    end
    map %w{--version -v} => :version

    desc 'server', 'Starts a hanami server'
    long_desc <<-EOS
    `hanami server` starts a server for the current hanami project.

    $ > hanami server

    $ > hanami server -p 4500
    EOS
    method_option :port, aliases: '-p', desc: 'The port to run the server on'
    method_option :server, desc: 'Choose a specific Rack::Handler (webrick, thin, etc)'
    method_option :rackup, desc: 'A rackup configuration file path to load (config.ru)'
    method_option :host, desc: 'The host address to bind to'
    method_option :debug, desc: 'Turn on debug output'
    method_option :warn, desc: 'Turn on warnings'
    method_option :daemonize, desc: 'If true, the server will daemonize itself (fork, detach, etc)'
    method_option :pid, desc: 'Path to write a pid file after daemonize'
    method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
    method_option :code_reloading, desc: 'Code reloading', type: :boolean, default: true
    method_option :help, desc: 'Displays the usage message'
    def server
      if options[:help]
        invoke :help, ['server']
      else
        require 'hanami/commands/server'
        Hanami::Commands::Server.new(options).start
      end
    end

    desc 'rackserver', '[private]'
    method_option :port, aliases: '-p', desc: 'The port to run the server on, '
    method_option :server, desc: 'choose a specific Rack::Handler, e.g. webrick, thin etc'
    method_option :rackup, desc: 'a rackup configuration file path to load (config.ru)'
    method_option :host, desc: 'the host address to bind to'
    method_option :debug, desc: 'turn on debug output'
    method_option :warn, desc: 'turn on warnings'
    method_option :daemonize, desc: 'if true, the server will daemonize itself (fork, detach, etc)'
    method_option :pid, desc: 'path to write a pid file after daemonize'
    method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
    method_option :help, desc: 'displays the usage message'
    def rackserver
      if options[:help]
        invoke :help, ['rackserver']
      else
        require 'hanami/server'
        Hanami::Server.new(options).start
      end
    end


    desc 'console', 'Starts a hanami console'
    long_desc <<-EOS
    `hanami console` starts the interactive hanami console.

    $ > hanami console --engine=pry
    EOS
    method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
    method_option :engine, desc: "Choose a specific console engine: (#{Hanami::Commands::Console::ENGINES.keys.join('/')})"
    method_option :help, desc: 'Displays the usage method'
    def console
      if options[:help]
        invoke :help, ['console']
      else
        Hanami::Commands::Console.new(options).start
      end
    end

    desc 'new APPLICATION_NAME', 'Generate a new hanami project'
    long_desc <<-EOS
      `hanami new` creates a new hanami project.
      You can specify various options such as the database to be used as well as the path and architecture.

      $ > hanami new fancy_app --application_name=admin

      $ > hanami new fancy_app --arch=app

      $ > hanami new fancy_app --hanami-head=true
    EOS
    method_option :database, aliases: ['-d', '--db'], desc: "Application database (#{Hanami::Generators::DatabaseConfig::SUPPORTED_ENGINES.keys.join('/')})", default: Hanami::Generators::DatabaseConfig::DEFAULT_ENGINE
    method_option :architecture, aliases: ['-a', '--arch'], desc: 'Project architecture (container/app)', default: Hanami::Commands::New::Abstract::DEFAULT_ARCHITECTURE
    method_option :application_name, desc: 'Application name, only for container', default: Hanami::Commands::New::Container::DEFAULT_APPLICATION_NAME
    method_option :application_base_url, desc: 'Application base url', default: Hanami::Commands::New::Abstract::DEFAULT_APPLICATION_BASE_URL
    method_option :template, desc: "Template engine (#{Hanami::Generators::TemplateEngine::SUPPORTED_ENGINES.join('/')})", default: Hanami::Generators::TemplateEngine::DEFAULT_ENGINE
    method_option :test, desc: "Project test framework (#{Hanami::Generators::TestFramework::VALID_FRAMEWORKS.join('/')})", default: Hanami::Hanamirc::DEFAULT_TEST_SUITE
    method_option :hanami_head, desc: 'Use hanami HEAD (true/false)', type: :boolean, default: false
    method_option :help, desc: 'Displays the usage method'
    def new(application_name)
      if options[:help]
        invoke :help, ['new']
      elsif options[:architecture] == 'app'
        Hanami::Commands::New::App.new(options, application_name).start
      else
        Hanami::Commands::New::Container.new(options, application_name).start
      end
    end

    desc 'routes', 'Prints the routes'
    long_desc <<-EOS
      `hanami routes` outputs all the registered routes to the console.
    EOS
    method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
    method_option :help, desc: 'Displays the usage method'
    def routes
      if options[:help]
        invoke :help, ['routes']
      else
        require 'hanami/commands/routes'
        Hanami::Commands::Routes.new(options).start
      end
    end

    require 'hanami/cli_sub_commands/db'
    register Hanami::CliSubCommands::DB, 'db', 'db [SUBCOMMAND]', 'Manage set of DB operations'

    require 'hanami/cli_sub_commands/generate'
    register Hanami::CliSubCommands::Generate, 'generate', 'generate [SUBCOMMAND]', 'Generate hanami classes'

    require 'hanami/cli_sub_commands/destroy'
    register Hanami::CliSubCommands::Destroy, 'destroy', 'destroy [SUBCOMMAND]', 'Destroy hanami classes'

    require 'hanami/cli_sub_commands/assets'
    register Hanami::CliSubCommands::Assets, 'assets', 'assets [SUBCOMMAND]', 'Manage assets'
  end
end
