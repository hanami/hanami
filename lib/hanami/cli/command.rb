# frozen_string_literal: true

require "dry/cli"
require "dry/cli/utils/files"
require "dry/inflector"

module Hanami
  module CLI
    class Command < Dry::CLI::Command
      def initialize(out: $stdout, fs: Dry::CLI::Utils::Files.new, inflector: Dry::Inflector.new)
        super()
        @out = out
        @fs = fs
        @inflector = inflector
      end

      private

      attr_reader :out

      attr_reader :fs

      attr_reader :inflector
    end
  end
end
