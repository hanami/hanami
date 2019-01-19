# frozen_string_literal: true

require "concurrent/hash"
require "hanami/utils/string"

module Hanami
  class Configuration
    # Hanami configuration security settings
    #
    # @since 2.0.0
    class Security
      def initialize
        @settings = Concurrent::Hash.new
        settings[:x_frame_options]         = Setting.new(HEADER_X_FRAME_OPTIONS, DEFAULT_X_FRAME_OPTIONS)
        settings[:x_content_type_options]  = Setting.new(HEADER_X_CONTENT_TYPE_OPTIONS, DEFAULT_X_CONTENT_TYPE_OPTIONS)
        settings[:x_xss_protection]        = Setting.new(HEADER_X_XSS_PROTECTION, DEFAULT_X_XSS_PROTECTION)
        settings[:content_security_policy] = ContentSecurityPolicy.new(HEADER_CONTENT_SECURITY_POLICY, DEFAULT_CONTENT_SECURITY_POLICY.dup)
      end

      def x_frame_options=(value)
        settings[:x_frame_options].value = value
      end

      def x_frame_options
        settings.fetch(:x_frame_options)
      end

      def x_content_type_options=(value)
        settings[:x_content_type_options].value = value
      end

      def x_content_type_options
        settings.fetch(:x_content_type_options)
      end

      def x_xss_protection=(value)
        settings[:x_xss_protection].value = value
      end

      def x_xss_protection
        settings.fetch(:x_xss_protection)
      end

      def content_security_policy=(options)
        settings[:content_security_policy].value = options
      end

      def content_security_policy
        settings.fetch(:content_security_policy)
      end

      def to_hash
        settings.each_with_object({}) do |(_, v), result|
          next if v.value.nil?

          result[v.header] = v.value
        end
      end

      private

      # X-Frame-Options
      HEADER_X_FRAME_OPTIONS = "X-Frame-Options"
      private_constant :HEADER_X_FRAME_OPTIONS

      DEFAULT_X_FRAME_OPTIONS = "DENY"
      private_constant :DEFAULT_X_FRAME_OPTIONS

      # X-Content-Type-Optionx
      HEADER_X_CONTENT_TYPE_OPTIONS = "X-Content-Type-Options"
      private_constant :HEADER_X_CONTENT_TYPE_OPTIONS

      DEFAULT_X_CONTENT_TYPE_OPTIONS = "nosniff"
      private_constant :DEFAULT_X_CONTENT_TYPE_OPTIONS

      # X-XSS-Protection
      HEADER_X_XSS_PROTECTION = "X-XSS-Protection"
      private_constant :HEADER_X_XSS_PROTECTION

      DEFAULT_X_XSS_PROTECTION = "1; mode=block"
      private_constant :DEFAULT_X_XSS_PROTECTION

      # Content-Security-Policy
      HEADER_CONTENT_SECURITY_POLICY = "Content-Security-Policy"
      private_constant :HEADER_CONTENT_SECURITY_POLICY

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

      # Security setting
      #
      # @api private
      # @since 2.0.0
      class Setting
        attr_accessor :header, :value

        def initialize(header, value)
          @header = header.freeze
          @value = value
        end
      end

      # Content security policy settings
      #
      # @api private
      # @since 2.0.0
      class ContentSecurityPolicy < Setting
        def value
          @value.map do |k, v|
            "#{Utils::String.dasherize(k)} #{v}" unless v.nil?
          end.compact.join("; ")
        end

        def [](key)
          @value[key]
        end

        def []=(key, value)
          @value[key] = value
        end
      end

      attr_reader :settings
    end
  end
end
