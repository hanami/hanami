require 'lotus/router'
require 'lotus/model'

module Lotus
  module Commands
    class DB
      attr_reader :command, :environment

      def initialize(command,environment)
        @command = command
        @environment = environment
        load_environment
      end

      def start
        execute 
      end

      private 

      def execute
        migrator.send(@command)
      rescue NotImplementedError
        raise 'Your command it is not supported.'
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
    end
  end 
end
