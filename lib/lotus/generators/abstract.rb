require 'delegate'

module Lotus
  module Generators
    # Abstract super class for generators
    #
    # @abstract
    # @since 0.2.0
    class Abstract < SimpleDelegator
      # @api private
      # @since x.x.x
      attr_reader :environment

      # Initialize a generator
      #
      # @param command [Thor] a Thor instance that comes from Lotus::Cli
      #
      # @since 0.2.0
      # @api private
      def initialize(command, environment)
        super(command)
        @environment = environment
      end

      # Start the generator
      #
      # @raise [NotImplementedError]
      #
      # @abstract
      # @since 0.2.0
      def start
        raise NotImplementedError
      end
    end
  end
end
