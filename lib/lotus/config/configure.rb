require 'lotus/config/mapper'

module Lotus
  module Config
    # Define configuration of application of
    # a specific environment
    #
    # @since x.x.x
    # @api private
    class Configure < Mapper
      private
      def error_message
        'You must specify a block or a file for configuration definition'
      end
    end
  end
end
