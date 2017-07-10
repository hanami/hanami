module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Generate
      include Hanami::Cli::Command
      register "generate", subcommand: true

      require "hanami/command_line/generate/app"
      require "hanami/command_line/generate/action"
      require "hanami/command_line/generate/mailer"
      require "hanami/command_line/generate/migration"
      require "hanami/command_line/generate/model"
      require "hanami/command_line/generate/secret"
    end
  end
end
