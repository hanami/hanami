# frozen_string_literal: true

require "hanami/cli"

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    # Register a command to expand Hanami CLI
    #
    # @param name [String] the command name
    # @param command [NilClass,Hanami::CLI::Command,Hanami::CLI::Commands::Command]
    #   the optional command
    # @param aliases [Array<String>] an optional list of aliases
    #
    # @since 1.1.0
    #
    # @example Third party gem
    #   require "hanami/cli/commands"
    #
    #   module Hanami
    #     module Webpack
    #       module CLI
    #         module Commands
    #           class Generate < Hanami::CLI::Command
    #             desc "Generate Webpack configuration"
    #
    #             def call(*)
    #               # ...
    #             end
    #           end
    #         end
    #       end
    #     end
    #   end
    #
    #   Hanami::CLI.register "generate webpack", Hanami::Webpack::CLI::Commands::Generate
    #
    #   # $ bundle exec hanami generate
    #   # Commands:
    #   #   hanami generate action APP ACTION                    # Generate an action for app
    #   #   hanami generate app APP                              # Generate an app
    #   #   hanami generate mailer MAILER                        # Generate a mailer
    #   #   hanami generate migration MIGRATION                  # Generate a migration
    #   #   hanami generate model MODEL                          # Generate a model
    #   #   hanami generate secret [APP]                         # Generate session secret
    #   #   hanami generate webpack                              # Generate Webpack configuration
    def self.register(name, command = nil, aliases: [], &blk)
      Commands.register(name, command, aliases: aliases, &blk)
    end

    # CLI commands registry
    #
    # @since 1.1.0
    # @api private
    module Commands
      extend Hanami::CLI::Registry

      require "hanami/cli/commands/version"
      require "hanami/cli/commands/command"
      require "hanami/cli/commands/server"
    end
  end
end
