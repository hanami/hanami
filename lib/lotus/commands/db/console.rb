require 'lotus/utils/class'

module Lotus
  module Commands
    class DB
      class Console

        attr_reader :name, :env_options, :environment

        def initialize(name, environment)
          @name        = name
          @environment = environment
          @env_options = environment.to_options
          @adapter     = Lotus::Config::Adapter.new(@name)
          load_config
        end

        def start
          exec connection_string
        end

        private

        def connection_string
          @adapter.connection_string
        end

        def load_config
          require @env_options[:env_config]
        end
      end
    end
  end
end
