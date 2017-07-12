module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Db
      include Hanami::Cli::Command
      register "db", subcommand: true

      require "hanami/command_line/db/version"
      require "hanami/command_line/db/create"
      require "hanami/command_line/db/drop"
      require "hanami/command_line/db/migrate"
      require "hanami/command_line/db/prepare"
      require "hanami/command_line/db/apply"
    end
  end
end
