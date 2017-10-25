module Hanami
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class Routes < Command
        requires "routes.inspector"

        desc "Prints routes"

        # @since 1.1.0
        # @api private
        def call(*)
          puts requirements['routes.inspector'].inspect
        end
      end
    end

    register "routes", Commands::Routes
  end
end
