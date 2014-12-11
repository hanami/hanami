require 'lotus/container'

module Lotus
  module Commands
    class Routes
      def start
        puts Lotus::Container.new.routes.inspector.to_s
      end
    end
  end
end
