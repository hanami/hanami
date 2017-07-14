module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Generate
        include Hanami::Cli::Command
        register "generate", subcommand: true

        require "hanami/cli/commands/generate/app"
        require "hanami/cli/commands/generate/action"
        require "hanami/cli/commands/generate/mailer"
        require "hanami/cli/commands/generate/migration"
        require "hanami/cli/commands/generate/model"
        require "hanami/cli/commands/generate/secret"
      end
    end
  end
end
