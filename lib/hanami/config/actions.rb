# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Config
    # Hanami actions config
    #
    # This exposes all the settings from the standalone `Hanami::Action` class, pre-configured with
    # sensible defaults for actions within a full Hanami app. It also provides additional settings
    # for further integration of actions with other full stack app components.
    #
    # @since 2.0.0
    # @api public
    class Actions
      include Dry::Configurable

      # @!attribute [rw] cookies
      #   Sets or returns a hash of cookie options for actions.
      #
      #   The hash is wrapped by {Hanami::Config::Actions::Cookies}, which also provides an
      #   `enabled?` method, returning true in the case of any options provided.
      #
      #   @example
      #     config.actions.cookies = {max_age: 300}
      #
      #   @return [Hanami::Config::Actions::Cookies]
      #
      #   @api public
      #   @since 2.0.0
      setting :cookies, default: {}, constructor: -> options { Cookies.new(options) }

      # @!attribute [rw] sessions
      #   Sets or returns the session store (and its options) for actions.
      #
      #   The given values are taken as an argument list to be passed to {Config::Sessions#initialize}.
      #
      #   The configured session store is used when setting up the app or slice
      #   {Slice::ClassMethods#router router}.
      #
      #   @example
      #     config.actions.sessions = :cookie, {secret: "xyz"}
      #
      #   @return [Config::Sessions]
      #
      #   @see Config::Sessions
      #   @see Slice::ClassMethods#router
      #
      #   @api public
      #   @since 2.0.0
      setting :sessions, constructor: proc { |storage, *options| Sessions.new(storage, *options) }

      # @!attribute [rw] csrf_protection
      #   Sets or returns whether CSRF protection should be enabled for action classes.
      #
      #   Defaults to true if {#sessions} is enabled. You can override this by explicitly setting a
      #   true or false value.
      #
      #   When true, this will include `Hanami::Action::CSRFProtection` in all action classes.
      #
      #   @return [Boolean]
      #
      #   @api public
      #   @since 2.0.0
      setting :csrf_protection

      # Returns the Content Security Policy config for actions.
      #
      # The resulting policy is set as a default `"Content-Security-Policy"` response header.
      #
      # @return [Hanami::Config::Actions::ContentSecurityPolicy]
      #
      # @api public
      # @since 2.0.0
      attr_accessor :content_security_policy

      # @!attribute [rw] method_override
      #   Sets or returns whether HTTP method override should be enabled for action classes.
      #
      #   Defaults to true. You can override this by explicitly setting a
      #   true or false value.
      #
      #   When true, this will mount `Rack::MethodOverride` in the Rack middleware stack of the App.
      #
      #   @return [Boolean]
      #
      #   @api public
      #   @since 2.1.0
      setting :method_override, default: true

      # @!attribute [rw] name_inference_base
      #   @api private
      #   @since 2.1.0
      setting :name_inference_base, default: "actions"

      # @!attribute [rw] view_name_inferrer
      #   @api private
      #   @since 2.1.0
      setting :view_name_inferrer, default: Slice::ViewNameInferrer

      # @!attribute [rw] view_name_inference_base
      #   @api private
      #   @since 2.1.0
      setting :view_name_inference_base, default: "views"

      # @api private
      attr_reader :base_config
      protected :base_config

      # @api private
      def initialize(*, **options)
        super()

        @base_config = Hanami::Action.config.dup
        @content_security_policy = ContentSecurityPolicy.new

        configure_defaults
      end

      # @api private
      def initialize_copy(source)
        super
        @base_config = source.base_config.dup
        @content_security_policy = source.content_security_policy.dup
      end
      private :initialize_copy

      # @api private
      def finalize!(app_config)
        @base_config.root_directory = app_config.root

        # A nil value for `csrf_protection` means it has not been explicitly configured
        # (neither true nor false), so we can default it to whether sessions are enabled
        self.csrf_protection = sessions.enabled? if csrf_protection.nil?

        if content_security_policy
          default_headers["Content-Security-Policy"] = content_security_policy.to_s
        end
      end

      private

      # Apply defaults for base config
      def configure_defaults
        self.default_headers = {
          "X-Frame-Options" => "DENY",
          "X-Content-Type-Options" => "nosniff",
          "X-XSS-Protection" => "1; mode=block"
        }
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_config.respond_to?(name)
          base_config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_config.respond_to?(name) || super
      end
    end
  end
end
