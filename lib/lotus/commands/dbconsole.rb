require 'lotus/utils/class'

module Lotus
  module Commands
    class DBConsole
      attr_reader :name, :options, :environment

      def initialize(name, environment)
        @name        = name
        @environment = environment
        @options     = environment.to_options
        load_config
      end

      def start
        exec connection_string
      rescue NotImplementedError
        raise 'Your adapter does not support db console.'
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
        adapter_class.new(mapper, adapter_config.uri).connection_string
      end

      def load_config
        require @options[:env_config]
      end
    end
  end
end
