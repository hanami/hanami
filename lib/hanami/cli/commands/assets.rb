module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Assets
        include Hanami::Cli::Command
        register "assets", subcommand: true

        require "hanami/cli/commands/assets/precompile"
      end
    end
  end
end
