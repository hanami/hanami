module Hanami
  module Config
    # Security policies are stored here.
    #
    # @since 0.3.0
    class Security
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Loader#_configure_controller_framework!
      X_FRAME_OPTIONS_HEADER = 'X-Frame-Options'.freeze

      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Loader#_configure_controller_framework!
      CONTENT_SECURITY_POLICY_HEADER = 'Content-Security-Policy'.freeze

      # @since x.x.x
      # @api private
      SEPARATOR = ';'.freeze

      # @since x.x.x
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
