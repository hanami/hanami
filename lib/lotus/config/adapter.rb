module Lotus
  module Config
    class Adapter

      def initialize(app_name)
        @app_name = app_name
      end

      def config
        configuration.adapter_config
      end

      def connection_string
        adapter_class.new(mapper, adapter_config.uri).connection_string
      end

      private 
      attr_reader :app_name

      def configuration
        if app_name
          app_constant = Lotus::Utils::Class.load_from_pattern!(Lotus::Utils::String.new(app_name).classify)
          Lotus::Utils::Class.load_from_pattern!("#{app_constant}::Application").load!
          Lotus::Utils::Class.load_from_pattern!("#{app_constant}::Model").configuration
        else
          Lotus::Model.configuration
        end
      end

      def mapper
        configuration.mapper
      end

      def adapter_class
        Lotus::Utils::Class.load_from_pattern!(adapter_config.class_name, Lotus::Model::Adapters)
      end
    end
  end
end
