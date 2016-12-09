require 'aruba'
require 'aruba/api'
require 'pathname'
require_relative 'env'


module RSpec
  module Support
    module Cli
      def self.included(spec)
        spec.before do
          aruba = Pathname.new(Dir.pwd).join('tmp', 'aruba')
          aruba.rmtree if aruba.exist?

          setup_aruba
        end
      end

      private

      def run_command(cmd, output = nil, exit_status: 0)
        run_simple "bundle exec #{cmd}", fail_on_error: false

        match_output(output)
        expect(last_command_started).to have_exit_status(exit_status)
      end

      def without_command(cmd)
        system("alias #{cmd}=/non_existent/binary; shopt -s expand_aliases")
        yield
      ensure
        system("unalias #{cmd}")
      end

      # Cross-platform way of finding an executable in the $PATH.
      #
      #   which('ruby') #=> /usr/bin/ruby
      #
      # Adapted from http://stackoverflow.com/a/5471032/498386
      def which(cmd)
        exts = if RSpec::Support::Env['PATHEXT']
                 RSpec::Support::Env['PATHEXT'].split(';')
               else
                 ['']
               end
        RSpec::Support::Env['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end

        return nil
      end

      def match_output(output)
        case output
        when String
          expect(all_output).to include(output)
        when Regexp
          expect(all_output).to match(output)
        when Array
          output.each { |o| match_output(o) }
        end
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
