require 'lotus/router'
require 'lotus/model'

module Lotus
  module Commands
    # Database migration 
    # 
    # Apply database changes, by runnning migrations up (migate) or down (rollback)
    #   
    # It is run with:
    #
    #   `bundle exec lotus db migrate`
    #   `bundle exec lotus db rollback`
    #
    # Allows user to specify lotus app and number of steps in case of rollback
    #
    #   `bundle exec lotus db migrate web`
    #   `bundle exec lotus db rollback web --step=2`
    #
    # This feature uses Lotus::Model::Migratior to execute migrations 
    #
    # @since x.x.x
    # @api private
    class DB

      DEFAULT_STEP = 1 
      APPS_DIRECOTRY = "apps".freeze
      MIGRATION_DIRECTORY = "db/migrations".freeze

      def initialize(name=nil, environment)
        @name         = name
        @environment  = environment
        @options      = @environment.to_options
        load_environment
        @migrator     = Lotus::Model::Migrator.new(adapter_config, logger: Lotus::Logger.new)
      end

      # Apply all migrations up located on specified directory
      # the directories could be located on root/db/migrations
      # or root/apps/#{app}/db/migrations
      def migrate
        @migrator.migrate(directory: migration_directory)
      end

      # Apply migrations down located on specified directory
      # the directories could be  root/db/migrations
      # or root/apps/#{app}/db/migrations
      # A number of steps could be specified by `--step` option
      def rollback
        @migrator.rollback(directory: migration_directory, step: step)
      end

      private 

      def config
        if @name
          app_constant = Lotus::Utils::Class.load_from_pattern!(Lotus::Utils::String.new(@name).classify)
          Lotus::Utils::Class.load_from_pattern!("#{app_constant}::Application").load!
          Lotus::Utils::Class.load_from_pattern!("#{app_constant}::Model").configuration
        else
          Lotus::Model.configuration
        end
      end

      def migration_directory
        if @name 
          pwd.join(APPS_DIRECOTRY, @name, MIGRATION_DIRECTORY)
        else
          pwd.join(MIGRATION_DIRECTORY)
        end
      end
      
      def pwd
        @pwd ||= Pathname.new(Dir.pwd)
      end
      
      def step
        @options.fetch(:step, DEFAULT_STEP) 
      end

      def adapter_config
        config.adapter_config
      end

      def load_environment
        require @environment.env_config
      end

      def merge_options(env)
        DEFAULTS.merge(env.to_options)
      end
    end
  end 
end
