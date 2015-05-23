require 'lotus/model/migrator'
require 'lotus/model/migration'

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
      # Allows user to specify number of steps when rollback
      #
      #   `bundle exec lotus db rollback -step=2`
      #
      # This feature uses Lotus::Model::Migratior to execute migrations 
      #
      # @since 0.3.0
      # @api private
      class Migrator

        # Default number of STEPS to roll back 
        DEFAULT_STEP = 1 

        def initialize(environment)
          @environment  = environment
          @options      = @environment.to_options
          load_environment
          @migrator     = Lotus::Model::Migrator.new
        end

        # Apply all migrations by calling Lotus::Model::Migrator
        #
        # @since 0.3.0
        # @api private
        # @see Lotus::Model::Migrator#migrate
        def migrate
          @migrator.migrate
        end

        # Apply all migrations by calling Lotus::Model::Migrator
        #
        # @since 0.3.0
        # @api private       
        # @see Lotus::Model::Migrator#rollback
        def rollback
          @migrator.rollback(step: step)
        end

        private 
        # Get number of steps
        #
        # @since 0.3.0
        # @api private
        def step
          @options.fetch(:step, DEFAULT_STEP) 
        end
       
        def load_environment
          require @environment.env_config
        end
      end
    end
  end
end
