module Hanami
  module Cli
    module Commands
      class Routes < Command
        requires "routes.inspector"
        desc "Prints the routes"

        option :environment, desc: 'Path to environment configuration (config/environment.rb)'

        def call(options)
          puts requirements['routes.inspector'].inspect
        end
      end
    end

    register "routes", Commands::Routes
  end
end
