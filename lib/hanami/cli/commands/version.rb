module Hanami
  class CLI
    module Commands
      class Version < Command
        desc "Print Hanami version"

        def call(*)
          puts "v#{Hanami::VERSION}"
        end
      end
    end

    register "version", Commands::Version, aliases: ["v", "-v", "--version"]
  end
end
