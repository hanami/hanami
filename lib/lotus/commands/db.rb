require 'lotus/router'
require 'lotus/model'

module Lotus
  module Commands
    class DB
      attr_reader :environment, :migrator

      def initialize(environment)
        @environment = environment
        load_environment
      end

      def migrate
        migrator.migrate
      end

      def rollback
        migrator.rollback
      end

      private 

      def migrator
        Lotus::Model::Migrator.new(adapter_config)
      end

      def adapter_config
        Lotus::Model.configuration.adapter_config
      end

      def load_environment
        require @environment.env_config
      end
    end
  end 
end
