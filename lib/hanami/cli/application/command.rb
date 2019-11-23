# frozen_string_literal: true

require_relative "../base_command"

module Hanami
  class CLI
    module Application
      # Hanami application CLI command (intended to run inside application directory)
      class Command < BaseCommand
        def self.inherited(klass)
          super

          klass.option :env, aliases: ["-e"], default: nil, desc: "Application environment"
        end

        attr_reader :application

        def initialize(application: nil, **opts)
          super(**opts)
          @application = application
        end

        def with_application(application)
          self.class.new(
            command_name: @command_name,
            application: application,
            out: out,
            inflector: application.inflector,
            files: files,
          )
        end

        private

        def run_command(klass, *args)
          klass.new(
            command_name: klass.name,
            application: application,
            out: out,
            inflector: application.inflector,
            files: files,
          ).call(*args)
        end
      end
    end
  end
end
