module Hanami
  module Cli
    module Commands
      module Destroy
        require "hanami/cli/commands/destroy/app"
        require "hanami/cli/commands/destroy/action"
        require "hanami/cli/commands/destroy/model"
        require "hanami/cli/commands/destroy/mailer"
        require "hanami/cli/commands/destroy/migration"
      end
    end

    register "destroy" do |prefix|
      prefix.register "app",       Commands::Destroy::App
      prefix.register "action",    Commands::Destroy::Action
      prefix.register "model",     Commands::Destroy::Model
      prefix.register "mailer",    Commands::Destroy::Mailer
      prefix.register "migration", Commands::Destroy::Migration
    end
  end
end
