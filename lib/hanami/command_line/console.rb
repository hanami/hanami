require 'hanami/commands/console'

module Hanami
  module CommandLine
    class Console
      include Hanami::Cli::Command

      register 'console'

      desc 'Starts a hanami console'

      option :environment, desc: 'Path to environment configuration (config/environment.rb)'
      # TODO: OptParser support enums, extract to CLI
      option :engine, desc: "Choose a specific console engine: (#{Hanami::Commands::Console::ENGINES.keys.join('/')})"

      def call(options)
        Hanami::Commands::Console.new(options).start
      end
    end
  end
end
