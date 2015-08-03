module Lotus
  module Commands
    class Routes
      def initialize(options)
        @environment = Lotus::Environment.new(options)
        @environment.require_application_environment
      end

      def start
        puts app.routes.inspector.to_s
      end

      private

      def app
        if @environment.container?
          Lotus::Container.new
        else
          Lotus::Application.applications.first.new
        end
      end
    end
  end
end
