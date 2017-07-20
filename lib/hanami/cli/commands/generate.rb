module Hanami
  class Cli
    module Commands
      module Generate
        require "hanami/cli/commands/generate/app"
        require "hanami/cli/commands/generate/action"
        require "hanami/cli/commands/generate/mailer"
        require "hanami/cli/commands/generate/migration"
        require "hanami/cli/commands/generate/model"
        require "hanami/cli/commands/generate/secret"
      end
    end

    register "generate", aliases: ["g"] do |prefix|
      prefix.register "app",       Commands::Generate::App
      prefix.register "action",    Commands::Generate::Action
      prefix.register "mailer",    Commands::Generate::Mailer
      prefix.register "migration", Commands::Generate::Migration
      prefix.register "model",     Commands::Generate::Model
      prefix.register "secret",    Commands::Generate::Secret
    end
  end
end
