# frozen_string_literal: true

require "dry/configurable"
require_relative "actions/cookies"
require_relative "actions/sessions"
require_relative "actions/content_security_policy"
require_relative "../slice/view_name_inferrer"

module Hanami
  class Configuration
    # Hanami actions configuration
    #
    # @since 2.0.0
    class Actions
      include Dry::Configurable

      setting :cookies, default: {}, constructor: -> options { Cookies.new(options) }
      setting :sessions, constructor: proc { |storage, *options| Sessions.new(storage, *options) }
      setting :csrf_protection

      setting :name_inference_base, default: "actions"
      setting :view_context_identifier, default: "views.context"
      setting :view_name_inferrer, default: Slice::ViewNameInferrer
      setting :view_name_inference_base, default: "views"

      attr_accessor :content_security_policy

      attr_reader :base_configuration
      protected :base_configuration

      def initialize(*, **options)
        super()

        @base_configuration = Hanami::Action.config.dup
        @content_security_policy = ContentSecurityPolicy.new do |csp|
          if assets_server_url = options[:assets_server_url]
            csp[:script_src] += " #{assets_server_url}"
            csp[:style_src] += " #{assets_server_url}"
          end
        end

        configure_defaults
      end

      def initialize_copy(source)
        super
        @base_configuration = source.base_configuration.dup
        @content_security_policy = source.content_security_policy.dup
      end

      def finalize!
        # A nil value for `csrf_protection` means it has not been explicitly configured
        # (neither true nor false), so we can default it to whether sessions are enabled
        self.csrf_protection = sessions.enabled? if csrf_protection.nil?

        if content_security_policy
          default_headers["Content-Security-Policy"] = content_security_policy.to_str
        end
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        base_configuration.settings + self.class.settings
      end

      private

      # Apply defaults for base configuration settings
      def configure_defaults
        self.default_request_format = :html
        self.default_response_format = :html

        self.default_headers = {
          "X-Frame-Options" => "DENY",
          "X-Content-Type-Options" => "nosniff",
          "X-XSS-Protection" => "1; mode=block"
        }
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_configuration.respond_to?(name)
          base_configuration.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_configuration.respond_to?(name) || super
      end
    end
  end
end
