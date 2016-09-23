require 'aruba'
require 'aruba/api'
require 'pathname'

module RSpec
  module Support
    module Cli
      def self.included(spec)
        spec.before do
          tmp = Pathname.new(Dir.pwd).join('tmp')
          tmp.rmtree if tmp.exist?

          setup_aruba
        end
      end

      private

      def run_command(cmd, output = nil, exit_status: 0)
        run_simple "bundle exec #{cmd}", fail_on_error: false

        case output
        when String
          expect(all_output).to include(output)
        when Regexp
          expect(all_output).to match(output)
        end

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
