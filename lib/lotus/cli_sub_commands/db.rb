
require 'lotus/cli_sub_commands/base'

module Lotus
  class CliSubCommands
    # A set of subcommands related to DB
    #
    # It is run with:
    #
    #   `bundle exec lotus db`
    #
    # @since x.x.x
    # @api private
    class DB < Base
      namespace :db

      desc 'console', 'start DB console'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def console(name = nil)
        invoke_help_action_or('console') do
          require 'lotus/commands/db/console'
          Lotus::Commands::DB::Console.new(options, name).start
        end
      end

      desc 'create', 'create database for current environment'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def create
        invoke_help_action_or('create') do
          assert_allowed_environment!
          require 'lotus/commands/db/create'
          Lotus::Commands::DB::Create.new(options).start
        end
      end

      desc 'drop', 'drop database for current environment'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def drop
        invoke_help_action_or('drop') do
          assert_allowed_environment!
          require 'lotus/commands/db/drop'
          Lotus::Commands::DB::Drop.new(options).start
        end
      end

      desc 'migrate', 'migrate database for current environment'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def migrate(version = nil)
        invoke_help_action_or('migrate') do
          require 'lotus/commands/db/migrate'
          Lotus::Commands::DB::Migrate.new(options, version).start
        end
      end

      desc 'apply', 'migrate, dump schema, delete migrations (experimental)'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def apply
        invoke_help_action_or('apply') do
          assert_development_environment!
          require 'lotus/commands/db/apply'
          Lotus::Commands::DB::Apply.new(options).start
        end
      end

      desc 'prepare', 'create and migrate database'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def prepare
        invoke_help_action_or('prepare') do
          assert_allowed_environment!
          require 'lotus/commands/db/prepare'
          Lotus::Commands::DB::Prepare.new(options).start
        end
      end

      # @since x.x.x
      # @api private
      desc 'version', 'current database version'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'
      def version
        invoke_help_action_or('version') do
          require 'lotus/commands/db/version'
          Lotus::Commands::DB::Version.new(options).start
        end
      end

      private

      # @since x.x.x
      # @api private
      def environment
        Lotus::Environment.new(options)
      end

      # @since x.x.x
      # @api private
      def assert_allowed_environment!
        if environment.environment?(:production)
          puts "Can't run this command in production mode"
          exit 1
        end
      end

      # @since x.x.x
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
