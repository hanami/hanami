module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Destroy
        include Hanami::Cli::Command
        register "destroy", subcommand: true

        require "hanami/cli/commands/destroy/app"
        require "hanami/cli/commands/destroy/action"
        require "hanami/cli/commands/destroy/model"
        require "hanami/cli/commands/destroy/mailer"
        require "hanami/cli/commands/destroy/migration"
      end
    end
  end
end
