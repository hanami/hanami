module Lotus
  module Commands
    class Routes
      def initialize(environment)
        environment.require_application_environment
      end

      def start
        puts Lotus::Container.new.routes.inspector.to_s
      end
    end
  end
end
