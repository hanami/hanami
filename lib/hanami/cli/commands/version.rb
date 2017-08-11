module Hanami
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class Version < Command
        desc "Print Hanami version"

        # @since 1.1.0
        # @api private
        def call(*)
          puts "v#{Hanami::VERSION}"
        end
      end
    end

    register "version", Commands::Version, aliases: ["v", "-v", "--version"]
  end
end
