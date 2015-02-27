require 'lotus/router'
require 'lotus/model'

module Lotus
  module Commands
    class DB

      DEFAULT_STEP = 1 
      APP_MIGRATION_DIRECOTRY = "apps/web/db/migrations".freeze
      MIGRATION_DIRECTORY = "db/migrations".freeze

      def initialize(name=nil, environment)
        @name         = name
        @environment  = environment
        @options      = @environment.to_options
        load_environment
        @migrator     = Lotus::Model::Migrator.new(adapter_config)
      end

      def migrate
        @migrator.migrate(directory: migration_directory)
      end

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
          pwd.join(APP_MIGRATION_DIRECOTRY)
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
