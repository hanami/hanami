# frozen_string_literal: true

require "concurrent/hash"

module Hanami
  class Configuration
    # Hanami configuration security settings
    #
    # @since 2.0.0
    class Security
      def initialize
        @settings = Concurrent::Hash.new
        self.x_frame_options = DEFAULT_X_FRAME_OPTIONS
        self.x_content_type_options = DEFAULT_X_CONTENT_TYPE_OPTIONS
        self.x_xss_protection = DEFAULT_X_XSS_PROTECTION
        self.content_security_policy = DEFAULT_CONTENT_SECURITY_POLICY.dup
      end

      def x_frame_options=(value)
        settings[:x_frame_options] = value
      end

      def x_frame_options
        settings.fetch(:x_frame_options)
      end

      def x_content_type_options=(value)
        settings[:x_content_type_options] = value
      end

      def x_content_type_options
        settings.fetch(:x_content_type_options)
      end

      def x_xss_protection=(value)
        settings[:x_xss_protection] = value
      end

      def x_xss_protection
        settings.fetch(:x_xss_protection)
      end

      def content_security_policy=(options)
        settings[:content_security_policy] = options
      end

      def content_security_policy
        settings.fetch(:content_security_policy)
      end

      private

      attr_reader :settings

      DEFAULT_X_FRAME_OPTIONS = "DENY"
      private_constant :DEFAULT_X_FRAME_OPTIONS

      DEFAULT_X_CONTENT_TYPE_OPTIONS = "nosniff"
      private_constant :DEFAULT_X_CONTENT_TYPE_OPTIONS

      DEFAULT_X_XSS_PROTECTION = "1; mode=block"
      private_constant :DEFAULT_X_XSS_PROTECTION

      DEFAULT_CONTENT_SECURITY_POLICY = {
        form_action: "'self'",
        frame_ancestors: "'self'",
        base_uri: "'self'",
        default_src: "'none'",
        script_src: "'self'",
        connect_src: "'self'",
        img_src: "'self' https: data:",
        style_src: "'self' 'unsafe-inline' https:",
        font_src: "'self'",
        object_src: "'none'",
        plugin_types: "application/pdf",
        child_src: "'self'",
        frame_src: "'self'",
        media_src: "'self'"
      }.freeze
      private_constant :DEFAULT_CONTENT_SECURITY_POLICY
    end
  end
end
