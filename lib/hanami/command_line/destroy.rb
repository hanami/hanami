module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Destroy
      include Hanami::Cli::Command
      register "destroy", subcommand: true

      require "hanami/command_line/destroy/app"
      require "hanami/command_line/destroy/action"
    end
  end
end
