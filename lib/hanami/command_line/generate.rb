module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Generate
      include Hanami::Cli::Command
      register "generate", subcommand: true

      require "hanami/command_line/generate/action"
    end
  end
end
