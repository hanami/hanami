require 'hanami/config/mapper'

module Hanami
  module Config
    # Define configuration of application of
    # a specific environment
    #
    # @since 0.2.0
    # @api private
    class Configure < Mapper
      private
      def error_message
        'You must specify a block or a file for configuration definition'
      end
    end
  end
end
