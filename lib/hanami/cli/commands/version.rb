module Hanami
  module Cli
    module Commands
      class Version < Command
        def call(*)
          puts "v#{Hanami::VERSION}"
        end
      end
    end

    register "version", Commands::Version, aliases: ["v", "-v", "--version"]
  end
end
