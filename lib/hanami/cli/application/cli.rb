# frozen_string_literal: true

require "hanami/cli"
require_relative "commands"

module Hanami
  class CLI
    module Application
      # Hanami application CLI
      class CLI < Hanami::CLI
        attr_reader :application

        def initialize(application: Hanami.application, commands: Commands)
          super(commands)
          @application = application

          application.init
        end

        private

        # TODO: we should make a prepare_command method upstream
        def parse(result, out)
          command, arguments = super

          if command.respond_to?(:with_application)
            application.config.env = arguments[:env] if arguments[:env]
            [command.with_application(application), arguments]
          else
            [command, arguments]
          end
        end
      end
    end
  end
end
