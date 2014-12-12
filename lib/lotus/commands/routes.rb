module Lotus
  module Commands
    class Routes
      def initialize(environment)
        @environment = environment
      end

      def start
        require @environment.env_config
        puts Lotus::Container.new.routes.inspector.to_s
      end
    end
  end
end
