module Hanami
  module Cli
    module Commands
      module Db
        require "hanami/cli/commands/db/version"
        require "hanami/cli/commands/db/create"
        require "hanami/cli/commands/db/drop"
        require "hanami/cli/commands/db/migrate"
        require "hanami/cli/commands/db/prepare"
        require "hanami/cli/commands/db/apply"
        require "hanami/cli/commands/db/console"
      end
    end

    register "db" do |prefix|
      prefix.register "version", Commands::Db::Version
      prefix.register "create",  Commands::Db::Create
      prefix.register "drop",    Commands::Db::Drop
      prefix.register "migrate", Commands::Db::Migrate
      prefix.register "prepare", Commands::Db::Prepare
      prefix.register "apply",   Commands::Db::Apply
      prefix.register "console", Commands::Db::Console
    end
  end
end
