module Lotus
  module Config
    # Cookies configuration
    #
    # @since x.x.x
    # @api private
    class Cookies

      # Return the routes for this application
      #
      # @return [Hash] options for cookies
      #
      # @since x.x.x
      # @api private
      attr_reader :default_options

      # Cookies configuration
      #
      # httponly option enabled by default.
      # Prevent attackers to steal cookies via JavaScript,
      # Eg. alert(document.cookie) will fail
      #
      # @param enabled [TrueClass, FalseClass] enable cookies
      # @param options [Hash] optional cookies options
      #
      # @since x.x.x
      # @api private
      #
      # @see https://github.com/rack/rack/blob/master/lib/rack/utils.rb #set_cookie_header!
      # @see https://www.owasp.org/index.php/HttpOnly
      def initialize(enabled = false, options = {})
        @enabled         = enabled
        @default_options = { httponly: true }.merge(options)
      end

      # Return if cookies are enabled
      #
      # @return [TrueClass, FalseClass] enabled cookies
      #
      # @since x.x.x
      # @api private
      def enabled?
        !!@enabled
      end
    end
  end
end
