require 'hanami/config/mapper'

module Hanami
  module Config
    class Mapping < Mapper
      private
      def error_message
        'You must specify a block or a file for database mapping definitions.'
      end
    end
  end
end
