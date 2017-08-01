module Hanami
  class CLI
    module Commands
      module Assets
        require "hanami/cli/commands/assets/precompile"
      end
    end

    register "assets precompile", Commands::Assets::Precompile
  end
end
