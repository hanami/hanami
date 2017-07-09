require 'hanami/commands/console'

module Hanami
  module CommandLine
    class Routes
      include Hanami::Cli::Command

      register 'routes'

      desc 'Prints the routes'

      option :environment, desc: 'Path to environment configuration (config/environment.rb)'

      def call(options)
        require 'hanami/commands/routes'
        Hanami::Commands::Routes.new(options).start
      end
    end
  end
end
