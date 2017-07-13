require 'hanami/cli'
require 'thor'
require 'hanami/cli_base'
require 'ostruct'

module Hanami
  module CommandLine
    include Hanami::Cli

    class Context < OpenStruct
      def initialize(data)
        data = data.each_with_object({}) do |(k, v), result|
          v = Utils::String.new(v) if v.is_a?(::String)
          result[k] = v
        end

        super(data)
        freeze
      end

      def binding
        super
      end
    end

    class Renderer
      TRIM_MODE = "-".freeze

      def call(template, context)
        ERB.new(template, nil, TRIM_MODE).result(context)
      end
    end

    require 'hanami/command_line/assets'
    require 'hanami/command_line/console'
    require 'hanami/command_line/db'
    require 'hanami/command_line/destroy'
    require 'hanami/command_line/generate'
    require 'hanami/command_line/new'
    require 'hanami/command_line/routes'
    require 'hanami/command_line/server'
    require 'hanami/command_line/version'
  end

  # @api private
  class OldCommandLine < Thor
    require 'hanami/cli_sub_commands/db'
    register Hanami::CliSubCommands::DB, 'db', 'db [SUBCOMMAND]', 'Manage set of DB operations'

    require 'hanami/cli_sub_commands/generate'
    register Hanami::CliSubCommands::Generate, 'generate', 'generate [SUBCOMMAND]', 'Generate hanami classes'

    require 'hanami/cli_sub_commands/destroy'
    register Hanami::CliSubCommands::Destroy, 'destroy', 'destroy [SUBCOMMAND]', 'Destroy hanami classes'

    require 'hanami/cli_sub_commands/assets'
    register Hanami::CliSubCommands::Assets, 'assets', 'assets [SUBCOMMAND]', 'Manage assets'
  end
end
