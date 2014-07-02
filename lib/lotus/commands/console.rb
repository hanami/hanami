require 'rack'

module Lotus
  module Commands
    class Console
      attr_reader :options

      def initialize(options)
        @options = default_options.merge(options)
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

      def default_options
        { applications: 'config/applications.rb' }
      end
    end
  end
end
