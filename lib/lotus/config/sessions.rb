require 'lotus/utils/string'

module Lotus
  module Config
    # Sessions configuration
    #
    # @since x.x.x
    # @api private
    class Sessions

      RACK_NAMESPACE = 'Rack::Session::%{class_name}'.freeze

      def initialize(identifier = nil, options = {}, config = nil)
        @identifier = identifier
        @options = options
        @config = config
      end

      def enabled?
        !!@identifier
      end

      def options
        default_options.merge(@options)
      end

      def middleware_class
        case @identifier
        when Symbol
          class_name = Utils::String.new(@identifier).classify
          RACK_NAMESPACE % { class_name: class_name }
        else
          @identifier
        end
      end

      private

      def default_options
        if @config
          { domain: @config.host, secure: @config.scheme == 'https' }
        else
          {}
        end
      end
    end
  end
end
