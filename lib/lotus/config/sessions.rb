require 'lotus/utils/string'

module Lotus
  module Config
    # Sessions configuration
    #
    # @since x.x.x
    # @api private
    class Sessions

      # Ruby namespace for Rack session adapters
      #
      # @since x.x.x
      # @api private
      RACK_NAMESPACE = 'Rack::Session::%s'.freeze

      # HTTP sessions configuration
      #
      # @param adapter [Symbol,String,Class] the session adapter
      # @param options [Hash] the optional session options
      # @param configuration [Lotus::Configuration] the application configuration
      #
      # @since x.x.x
      # @api private
      #
      # @see http://www.rubydoc.info/github/rack/rack/Rack/Session/Abstract/ID
      def initialize(adapter = nil, options = {}, configuration = nil)
        @adapter       = adapter
        @options       = options
        @configuration = configuration
      end

      # Check if the sessions are enabled
      #
      # @return [FalseClass,TrueClass] the result of the check
      #
      # @since x.x.x
      # @api private
      def enabled?
        !!@adapter
      end

      # Returns the Rack middleware and the options
      #
      # @return [Array] Rack middleware and options
      #
      # @since x.x.x
      # @api private
      def middleware
        middleware = case @adapter
        when Symbol
          RACK_NAMESPACE % Utils::String.new(@adapter).classify
        else
          @adapter
        end

        [middleware, options]
      end

      private

      # @since x.x.x
      # @api private
      def options
        default_options.merge(@options)
      end

      # @since x.x.x
      # @api private
      def default_options
        if @configuration
          { domain: @configuration.host, secure: @configuration.ssl? }
        else
          {}
        end
      end
    end
  end
end
