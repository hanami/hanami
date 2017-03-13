require 'hanami/config/mapper'

module Hanami
  # @since 0.1.0
  # @api private
  module Config
    # Defines a route set
    #
    # @since 0.1.0
    # @api private
    class Routes < Mapper
      private
      # @since 0.1.0
      # @api private
      def error_message
        'You must specify a block or a file for routes definitions.'
      end
    end
  end
end
