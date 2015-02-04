require 'lotus/utils/class'

module Lotus
  module Commands
    class DBConsole
      attr_reader :name, :env_options, :environment, :options

      def initialize(name, environment, options)
        @name        = name
        @environment = environment
        @env_options = environment.to_options
        @options     = options
        load_config
      end

      def start
        exec connection_string
      end

      private

      def config
        Lotus::Model.configuration
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
        adapter_class.new(mapper, adapter_config.uri).connection_string(options)
      end

      def load_config
        require @env_options[:env_config]
      end
    end
  end
end
