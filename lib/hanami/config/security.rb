module Hanami
  # @since 0.3.0
  # @api private
  module Config
    # Security policies are stored here.
    #
    # @since 0.3.0
    class Security
      # @since 0.3.0
      # @api private
      X_FRAME_OPTIONS_HEADER = 'X-Frame-Options'.freeze

      # @since 0.8.0
      # @api private
      X_CONTENT_TYPE_OPTIONS_HEADER = 'X-Content-Type-Options'.freeze

      # @since 0.8.0
      # @api private
      X_XSS_PROTECTION_HEADER = 'X-XSS-Protection'.freeze

      # @since 0.3.0
      # @api private
      CONTENT_SECURITY_POLICY_HEADER = 'Content-Security-Policy'.freeze

      # @since 0.8.0
      # @api private
      SEPARATOR = ';'.freeze

      # @since 0.8.0
      # @api private
      SPACED_SEPARATOR = "#{ SEPARATOR } ".freeze

      # X-Frame-Options headers' value
      #
      # @overload x_frame_options(value)
      #   Sets the given value
      #   @param value [String] for X-Frame-Options header.
      #
      # @overload x_frame_options
      #   Gets the value
      #   @return [String] X-Frame-Options header's value
      #
      # @since 0.3.0
      def x_frame_options(value = nil)
        if value.nil?
          @x_frame_options
        else
          @x_frame_options = value
        end
      end

      # X-Content-Type-Options headers' value
      #
      # @overload x_content_type_options(value)
      #   Sets the given value
      #   @param value [String] for X-Content-Type-Options header.
      #
      # @overload x_content_type_options
      #   Gets the value
      #   @return [String] X-Content-Type-Options header's value
      #
      # @since 0.8.0
      def x_content_type_options(value = nil)
        if value.nil?
          @x_content_type_options
        else
          @x_content_type_options = value
        end
      end

      # X-XSS-Protection headers' value
      #
      # @overload x_xss_protection(value)
      #   Sets the given value
      #   @param value [String] for X-XSS-Protection header.
      #
      # @overload x_xss_protection
      #   Gets the value
      #   @return [String] X-XSS-Protection header's value
      #
      # @since 0.8.0
      def x_xss_protection(value = nil)
        if value.nil?
          @x_xss_protection
        else
          @x_xss_protection = value
        end
      end

      # Content-Policy-Security headers' value
      #
      # @overload content_security_policy(value)
      #   Sets the given value
      #   @param value [String] for Content-Security-Policy header.
      #
      # @overload content_security_policy
      #   Gets the value
      #   @return [String] Content-Security-Policy header's value
      #
      # @since 0.3.0
      def content_security_policy(value = nil)
        if value.nil?
          @content_security_policy
        else
          @content_security_policy = value.split(SEPARATOR).map(&:strip).join(SPACED_SEPARATOR)
        end
      end
    end
  end
end
