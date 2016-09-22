require 'aruba'
require 'aruba/api'

module RSpec
  module Support
    module Cli
      def self.included(spec)
        spec.before do
          setup_aruba
        end
      end

      private

      def run_command(cmd, output, exit_status: 0)
        run_simple "bundle exec #{cmd}"

        expect(all_output).to match(/#{output}/)
        expect(last_command_started).to have_exit_status(exit_status)
      end

      def all_output
        all_commands.map(&:output).join("\n")
      end
    end
  end
end

RSpec.configure do |config|
  config.include Aruba::Api,          type: :cli
  config.include RSpec::Support::Cli, type: :cli
end
