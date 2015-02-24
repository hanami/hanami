require 'lotus/router'
require 'lotus/model'

module Lotus
  module Commands
    class DB
      attr_reader :environment, :options
      DEFAULTS = { step:1 }

      def initialize(environment)
        @environment = environment
        @options = merge_options(@environment)
      end

      def migrate
        load_environment
        migrator.migrate
      end

      def rollback
        load_environment
        migrator.rollback(step: step)
      end

      private 

      def step
        options.fetch(:step) 
      end

      def migrator
        Lotus::Model::Migrator.new(adapter_config)
      end

      def adapter_config
        Lotus::Model.configuration.adapter_config
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
