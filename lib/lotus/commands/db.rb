module Lotus
  module Commands
    class DB < Thor
      namespace :db

      desc 'db console', 'start DB console'

      desc 'console', 'start DB console'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def console(name = nil)
        if options[:help]
          invoke :help, ['console']
        else
          require 'lotus/commands/db/console'
          Lotus::Commands::DB::Console.new(name, environment).start
        end
      end

      desc 'db create', 'create database'

      desc 'create', 'create database for current environment'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def create
        if options[:help]
          invoke :help, ['create']
        else
          assert_allowed_environment!
          require 'lotus/commands/db/create'
          Lotus::Commands::DB::Create.new(environment).start
        end
      end

      desc 'db drop', 'drop database'

      desc 'drop', 'drop database for current environment'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def drop
        if options[:help]
          invoke :help, ['drop']
        else
          assert_allowed_environment!
          require 'lotus/commands/db/drop'
          Lotus::Commands::DB::Drop.new(environment).start
        end
      end

      desc 'db migrate', 'migrate database'

      desc 'migrate', 'migrate database for current environment'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def migrate(version = nil)
        if options[:help]
          invoke :help, ['migrate']
        else
          require 'lotus/commands/db/migrate'
          Lotus::Commands::DB::Migrate.new(environment, version).start
        end
      end

      desc 'db apply', 'apply database changes'

      desc 'apply', 'migrate, dump schema, delete migrations (experimental)'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def apply
        if options[:help]
          invoke :help, ['apply']
        else
          assert_development_environment!
          require 'lotus/commands/db/apply'
          Lotus::Commands::DB::Apply.new(environment).start
        end
      end

      desc 'db prepare', 'prepare database'

      desc 'prepare', 'create and migrate database'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def prepare
        if options[:help]
          invoke :help, ['prepare']
        else
          assert_allowed_environment!
          require 'lotus/commands/db/prepare'
          Lotus::Commands::DB::Prepare.new(environment).start
        end
      end

      desc 'db version', 'database version'

      desc 'version', 'current database version'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def version
        if options[:help]
          invoke :help, ['version']
        else
          require 'lotus/commands/db/version'
          Lotus::Commands::DB::Version.new(environment).start
        end
      end

      private

      def environment
        Lotus::Environment.new(options)
      end

      def assert_allowed_environment!
        if environment.environment?(:production)
          puts "Can't run this command in production mode"
          exit 1
        end
      end

      def assert_development_environment!
        unless environment.environment?(:development)
          puts "This command can be ran only in development mode"
          exit 1
        end
      end
    end
  end
end
