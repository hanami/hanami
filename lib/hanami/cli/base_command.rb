# frozen_string_literal: true

require "dry/inflector"
require "hanami/cli/command"
require "hanami/utils/files"

module Hanami
  class CLI
    # This should really be named `Command`, but I'm temporarily using a
    # different name to make it easier to drop this in without having to mess
    # with existing code
    class BaseCommand < Hanami::CLI::Command
      attr_reader :out
      attr_reader :inflector
      attr_reader :files

      def initialize(
        command_name:,
        out: $stdout,
        inflector: Dry::Inflector.new,
        files: Hanami::Utils::Files
      )
        super(command_name: command_name)

        @out = out
        @inflector = inflector
        @files = files
      end

      private

      def run_command(klass, *args)
        klass.new(
          command_name: klass.name,
          application: application,
          out: out,
          files: files,
        ).call(*args)
      end

      def measure(desc, &block)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block.call
        stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        out.puts "=> #{desc} in #{(stop - start).round(1)}s"
      end
    end
  end
end
