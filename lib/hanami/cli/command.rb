# frozen_string_literal: true

require "dry/cli"

module Hanami
  module CLI
    class Command < Dry::CLI::Command
      def initialize(out: $stdout)
        super()
        @out = out
      end

      private

      attr_reader :out
    end
  end
end
