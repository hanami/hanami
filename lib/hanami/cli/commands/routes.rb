module Hanami
  class Cli
    module Commands
      class Routes < Command
        requires "routes.inspector"

        desc "Prints routes"

        def call(options)
          puts requirements['routes.inspector'].inspect
        end
      end
    end

    register "routes", Commands::Routes
  end
end
