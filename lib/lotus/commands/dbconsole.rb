require 'lotus/utils/class'

module Lotus
  module Commands
    class DBConsole
      attr_reader :name, :env_options, :environment

      def initialize(name, environment)
        @name        = name
        @environment = environment
        @env_options = environment.to_options
        load_config
      end

      def start
        exec connection_string
      end

      private

      def config
        if name
          app_constant = Lotus::Utils::Class.load!(Lotus::Utils::String.new(name).classify)
          Lotus::Utils::Class.load!('Application', app_constant).load!
          Lotus::Utils::Class.load!('Model', app_constant).configuration
        else
          Lotus::Model.configuration
        end
      end

      def adapter_config
        config.adapter_config
      end

      def mapper
        config.mapper
      end

      def adapter_class
        Lotus::Utils::Class.load!(adapter_config.class_name, Lotus::Model::Adapters)
      end

      def connection_string
        adapter_class.new(mapper, adapter_config.uri).connection_string
      end

      def load_config
        require @env_options[:env_config]
      end
    end
  end
end
