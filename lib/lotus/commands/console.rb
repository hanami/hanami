require 'rack'

module Lotus
  module Commands
    class Console
      attr_reader :options

      def initialize(env)
        @options = _extract_options(env)
      end

      def start
        # Clear out ARGV so Pry/IRB don't attempt to parse the rest
        ARGV.shift until ARGV.empty?

        require File.expand_path(options[:applications], Dir.pwd)

        if defined?(Pry)
          Pry.start
        else
          require 'irb'
          IRB.start
        end
      end

      private

      def _extract_options(env)
        default_options.merge(env.to_options)
      end

      def default_options
        { applications: 'config/applications.rb' }
      end
    end
  end
end
