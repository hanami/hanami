module Lotus
  module Commands
    class DBConsole
      attr_reader :options

      def initialize(environment)
        @environment = environment
        @options     = environment.to_options
      end

      def start
        require @environment.env_config.to_s
      end

    end
  end
end
