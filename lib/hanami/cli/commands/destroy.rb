module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      module Destroy
        require "hanami/cli/commands/destroy/app"
        require "hanami/cli/commands/destroy/action"
        require "hanami/cli/commands/destroy/model"
        require "hanami/cli/commands/destroy/mailer"
        require "hanami/cli/commands/destroy/migration"
      end
    end

    register "destroy", aliases: ["d"] do |prefix|
      prefix.register "app",       Commands::Destroy::App
      prefix.register "action",    Commands::Destroy::Action
      prefix.register "model",     Commands::Destroy::Model
      prefix.register "mailer",    Commands::Destroy::Mailer
      prefix.register "migration", Commands::Destroy::Migration
    end
  end
end
