require 'lotus/environment'
require 'lotus/application'

module Lotus
  module Commands
    # Evaluate a file or expression with the preloaded environment and application.
    #
    # It is run with:
    #
    #   `bundle exec lotus runner ./my_script.rb`
    #
    # or
    #
    #   `bundle exec lotus runner 'puts Lotus.env'`
    #
    # @since x.x.x
    # @api private
    class Runner
      # @param options [Hash] Environment's options
      # @param expression_or_file [String] Expression or file to evaluate
      #
      # @since x.x.x
      # @see Lotus::Environment#initialize
      # @see Lotus::Environment#require_application_environment
      # @see Lotus::Application.preload!
      def initialize(options, expression_or_file)
        @expression_or_file = expression_or_file
        raise ArgumentError.new("Provide file or expression to execute") if @expression_or_file.nil?

        @environment = Lotus::Environment.new(options)
        @environment.require_application_environment
        Lotus::Application.preload!
      end

      # Evaluate a file or expression with the preloaded environment and application.
      #
      # @since x.x.x
      def start
        if File.exists?(@expression_or_file)
          $0 = @expression_or_file
          Kernel.load(@expression_or_file)
        else
          eval(@expression_or_file, binding, __FILE__, __LINE__)
        end
      end
    end
  end
end
