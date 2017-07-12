require 'hanami/cli'
require 'thor'
require 'hanami/cli_base'
require 'hanami/commands/new/app'
require 'hanami/commands/new/container'
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
      def call(template, context)
        ERB.new(template).result(context)
      end
    end

    require "hanami/command_line/generate"
    require "hanami/command_line/destroy"
    require 'hanami/command_line/console'
    require "hanami/command_line/db"
    require 'hanami/command_line/routes'
    require 'hanami/command_line/server'
    require 'hanami/command_line/version'
  end

  # @api private
  class OldCommandLine < Thor
    extend CliBase

    desc 'new PROJECT_NAME', 'Generate a new hanami project'
    long_desc <<-EOS
`hanami new` creates a new hanami project.
You can specify various options such as the database to be used as well as the path and architecture.

$ > hanami new fancy_app --application_name=admin

$ > hanami new fancy_app --arch=app

$ > hanami new fancy_app --hanami-head=true
    EOS
    method_option :database, aliases: ['-d', '--db'], desc: "Application database (#{Hanami::Generators::DatabaseConfig::SUPPORTED_ENGINES.keys.join('/')})", default: Hanami::Generators::DatabaseConfig::DEFAULT_ENGINE
    method_option :architecture, aliases: ['-a', '--arch'], desc: 'Project architecture (container/app)', default: Hanami::Commands::New::Abstract::DEFAULT_ARCHITECTURE
    method_option :application_name, desc: 'Application name, only for container', default: Hanami::Commands::New::Container::DEFAULT_APPLICATION_NAME
    method_option :application_base_url, desc: 'Application base url', default: Hanami::Commands::New::Abstract::DEFAULT_APPLICATION_BASE_URL
    method_option :template, desc: "Template engine (#{Hanami::Generators::TemplateEngine::SUPPORTED_ENGINES.join('/')})", default: Hanami::Generators::TemplateEngine::DEFAULT_ENGINE
    method_option :test, desc: "Project test framework (#{Hanami::Generators::TestFramework::VALID_FRAMEWORKS.join('/')})", default: Hanami::Hanamirc::DEFAULT_TEST_SUITE
    method_option :hanami_head, desc: 'Use hanami HEAD (true/false)', type: :boolean, default: false
    method_option :help, desc: 'Displays the usage method'
    # @api private
    def new(application_name=nil)
      if options[:help]
        invoke :help, ['new']
      elsif application_name.nil?
        warn %(`hanami new` was called with no arguments\nUsage: `hanami new PROJECT_NAME`)
        exit(1)
      elsif options[:architecture] == 'app'
        Hanami::Commands::New::App.new(options, application_name).start
      else
        Hanami::Commands::New::Container.new(options, application_name).start
      end
    end

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
