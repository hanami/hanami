module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Assets
      include Hanami::Cli::Command
      register "assets", subcommand: true

      require "hanami/command_line/assets/precompile"
    end
  end
end
