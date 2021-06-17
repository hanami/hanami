# frozen_string_literal: true

require "hanami/cli"
require_relative "commands"

module Hanami
  class CLI
    module Application
      # Hanami application CLI
      class CLI < Hanami::CLI
        attr_reader :application

        def initialize(application: nil, commands: Commands)
          super(commands)
          @application = application
        end

        private

        # TODO: we should make a prepare_command method upstream
        def parse(result, out)
          command, arguments = super

          if command.respond_to?(:with_application)
            # Set HANAMI_ENV before the application inits to ensure all aspects
            # of the boot process respect the provided env
            ENV["HANAMI_ENV"] = arguments[:env] if arguments[:env]

            require "hanami/init"
            application = Hanami.application

            [command.with_application(application), arguments]
          else
            [command, arguments]
          end
        end
      end
    end
  end
end
