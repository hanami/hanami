require 'delegate'

module Lotus
  module Generators
    # Abstract super class for generators
    #
    # @abstract
    # @since x.x.x
    class Abstract < SimpleDelegator
      # Initialize a generator
      #
      # @param command [Thor] a Thor instance that comes from Lotus::Cli
      #
      # @since x.x.x
      # @api private
      def initialize(command)
        super(command)
      end

      # Start the generator
      #
      # @raise [NotImplementedError]
      #
      # @abstract
      # @since x.x.x
      def start
        raise NotImplementedError
      end
    end
  end
end
