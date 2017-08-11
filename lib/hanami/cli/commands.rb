require 'hanami/cli'
require 'ostruct'

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
    #             desc "Generate Webpack config"
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

      # CLI command context
      #
      # @since 1.1.0
      # @api private
      class Context < OpenStruct
        # @since 1.1.0
        # @api private
        def initialize(data)
          data = data.each_with_object({}) do |(k, v), result|
            v = Utils::String.new(v) if v.is_a?(::String)
            result[k] = v
          end

          super(data)
          freeze
        end

        # @since 1.1.0
        # @api private
        def with(data)
          self.class.new(to_h.merge(data))
        end

        # @since 1.1.0
        # @api private
        def binding
          super
        end
      end

      require "hanami/cli/commands/command"
      require "hanami/cli/commands/assets"
      require "hanami/cli/commands/console"
      require "hanami/cli/commands/db"
      require "hanami/cli/commands/destroy"
      require "hanami/cli/commands/generate"
      require "hanami/cli/commands/new"
      require "hanami/cli/commands/routes"
      require "hanami/cli/commands/server"
      require "hanami/cli/commands/version"
    end
  end
end
