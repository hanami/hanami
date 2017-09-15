require "hanami/cli/commands"

module Hanami
  module Plugin
    module CLI
      class Version < Hanami::CLI::Command
        desc "Print Hanami plugin version"

        def call(*)
          puts "v#{Hanami::Plugin::VERSION}"
        end
      end
    end
  end
end

Hanami::CLI.register "plugin version", Hanami::Plugin::CLI::Version
