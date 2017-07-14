module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Db
        include Hanami::Cli::Command
        register "db", subcommand: true

        require "hanami/cli/commands/db/version"
        require "hanami/cli/commands/db/create"
        require "hanami/cli/commands/db/drop"
        require "hanami/cli/commands/db/migrate"
        require "hanami/cli/commands/db/prepare"
        require "hanami/cli/commands/db/apply"
        require "hanami/cli/commands/db/console"
      end
    end
  end
end
