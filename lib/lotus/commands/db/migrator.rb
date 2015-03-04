require 'lotus/config/adapter'

module Lotus
  module Commands
    class DB
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
      # @since 0.3.0
      # @api private
      class Migrator

        # Default number of STEPS to roll back 
        DEFAULT_STEP = 1 
        APPS_DIRECOTRY = "apps".freeze
        MIGRATION_DIRECTORY = "db/migrations".freeze

        def initialize(name=nil, environment)
          @name         = name
          @environment  = environment
          @options      = @environment.to_options
          @adapter      = Lotus::Config::Adapter.new(@name)
          load_environment
          @migrator     = Lotus::Model::Migrator.new(@adapter.config, logger: Lotus::Logger.new)
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
        attr_reader :name

        # It retuns the default migration directory or lotus  
        # app migration 
        def migration_directory
          if name 
            pwd.join(APPS_DIRECOTRY, name, MIGRATION_DIRECTORY)
          else
            pwd.join(MIGRATION_DIRECTORY)
          end
        end

        def adapter_config
        end
        
        def step
          @options.fetch(:step, DEFAULT_STEP) 
        end
         
        def pwd
          @pwd ||= Pathname.new(Dir.pwd)
        end
        
        def load_environment
          require @environment.env_config
        end
      end
    end
  end
end
