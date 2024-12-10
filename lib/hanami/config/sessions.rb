require 'ipaddr'
require 'hanami/cyg_utils/string'

module Hanami
  # @since 0.2.0
  # @api private
  module Config
    # Sessions configuration
    #
    # @since 0.2.0
    # @api private
    class Sessions

      # Ruby namespace for Rack session adapters
      #
      # @since 0.2.0
      # @api private
      RACK_NAMESPACE = 'Rack::Session::%s'.freeze

      # Localhost string for detecting localhost host configuration
      #
      # @since 0.2.0
      # @api private
      BLACKLISTED_DOMAINS = %w(localhost).freeze

      # HTTP sessions configuration
      #
      # @param adapter [Symbol,String,Class] the session adapter
      # @param options [Hash] the optional session options
      # @param configuration [Hanami::Configuration] the application configuration
      #
      # @since 0.2.0
      # @api private
      #
      # @see http://www.rubydoc.info/github/rack/rack/Rack/Session/Abstract/ID
      # @see https://www.rubydoc.info/github/rack/rack/Rack/Session/Cookie
      def initialize(adapter = nil, options = {}, configuration = nil)
        @adapter       = adapter
        @options       = options
        @configuration = configuration
      end

      # Check if the sessions are enabled
      #
      # @return [FalseClass,TrueClass] the result of the check
      #
      # @since 0.2.0
      # @api private
      def enabled?
        !!@adapter
      end

      # Returns the Rack middleware and the options
      #
      # @return [Array] Rack middleware and options
      #
      # @since 0.2.0
      # @api private
      def middleware
        middleware = case @adapter
                     when Symbol
                       RACK_NAMESPACE % CygUtils::String.classify(@adapter)
                     else
                       @adapter
                     end

        [middleware, options]
      end

      private

      # @since 0.2.0
      # @api private
      def options
        default_options.merge(@options)
      end

      # @since 0.2.0
      # @api private
      def default_options
        result = if @configuration
          { domain: domain, secure: @configuration.ssl? }
        else
          {}
        end

        if s = cookies_adapter_serializer
          result[:coder] = s
        end

        result
      end

      # @since 0.2.0
      # @api private
      def domain
        domain = @configuration.host
        if !BLACKLISTED_DOMAINS.include?(domain) && !ip_address?(domain)
          domain
        end
      end

      # @since 0.2.0
      # @api private
      def ip_address?(string)
        !!IPAddr.new(string) rescue false
      end

      # @since 1.3.5
      # @api private
      def cookies_adapter_serializer
        return nil unless @adapter == :cookie

        require "rack/session/cookie"
        Rack::Session::Cookie::Base64::JSON.new
      end
    end
  end
end
