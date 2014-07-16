require 'lotus/utils/string'

module Lotus
  module Config
    # Sessions configuration
    #
    # @since x.x.x
    # @api private
    class Sessions

      def initialize(identifier = nil, options = {})
        if identifier
          @identifier = identifier
          @options = options
          @enabled = true
        else
          @enabled = false
        end
      end

      def enabled?
        @enabled
      end

      def middleware
        [resolve_identifier, [@options], nil]
      end

      private

      def resolve_identifier
        case @identifier
        when Symbol
          class_name = Utils::String.new(@identifier).classify
          "Rack::Session::#{class_name}"
        else
          @identifier
        end
      end
    end
  end
end
