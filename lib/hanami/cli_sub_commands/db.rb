module Hanami
  class CliSubCommands
    # A set of subcommands related to DB
    #
    # It is run with:
    #
    #   `bundle exec hanami db`
    #
    # @since 0.6.0
    # @api private
    class DB < Thor
      namespace :db

      desc 'console', 'Start DB console'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def console(name = nil)
        if options[:help]
          invoke :help, ['console']
        else
          require 'hanami/commands/db/console'
          Hanami::Commands::DB::Console.new(options, name).start
        end
      end

      desc 'create', 'Create database for current environment'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def create
        if options[:help]
          invoke :help, ['create']
        else
          assert_allowed_environment!
          require 'hanami/commands/db/create'
          Hanami::Commands::DB::Create.new(options).start
        end
      end

      desc 'drop', 'Drop database for current environment'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def drop
        if options[:help]
          invoke :help, ['drop']
        else
          assert_allowed_environment!
          require 'hanami/commands/db/drop'
          Hanami::Commands::DB::Drop.new(options).start
        end
      end

      desc 'migrate', 'Migrate database for current environment'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def migrate(version = nil)
        if options[:help]
          invoke :help, ['migrate']
        else
          require 'hanami/commands/db/migrate'
          Hanami::Commands::DB::Migrate.new(options, version).start
        end
      end

      desc 'apply', 'Migrate, dump schema, delete migrations (experimental)'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def apply
        if options[:help]
          invoke :help, ['apply']
        else
          assert_development_environment!
          require 'hanami/commands/db/apply'
          Hanami::Commands::DB::Apply.new(options).start
        end
      end

      desc 'prepare', 'Create and migrate database'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def prepare
        if options[:help]
          invoke :help, ['prepare']
        else
          assert_allowed_environment!
          require 'hanami/commands/db/prepare'
          Hanami::Commands::DB::Prepare.new(options).start
        end
      end

      # @since 0.6.0
      # @api private
      desc 'version', 'Current database version'
      method_option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      def version
        if options[:help]
          invoke :help, ['version']
        else
          require 'hanami/commands/db/version'
          Hanami::Commands::DB::Version.new(options).start
        end
      end

      private

      # @since 0.6.0
      # @api private
      def environment
        Hanami::Environment.new(options)
      end

      # @since 0.6.0
      # @api private
      def assert_allowed_environment!
        if environment.environment?(:production)
          puts "Can't run this command in production mode"
          exit 1
        end
      end

      # @since 0.6.0
      # @api private
      def assert_development_environment!
        unless environment.environment?(:development)
          puts "This command can be ran only in development mode"
          exit 1
        end
      end
    end
  end
end
