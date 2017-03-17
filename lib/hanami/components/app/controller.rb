require 'hanami/action/session'
require 'hanami/action/routing_helpers'

module Hanami
  # @since 0.9.0
  # @api private
  module Components
    # @since 0.9.0
    # @api private
    module App
      # hanami-controller configuration for a sigle Hanami application in the project.
      #
      # @since 0.9.0
      # @api private
      class Controller
        STRICT_TRANSPORT_SECURITY_HEADER = 'Strict-Transport-Security'.freeze
        STRICT_TRANSPORT_SECURITY_DEFAULT_VALUE = 'max-age=31536000'.freeze

        # Configure hanami-controller for a single Hanami application in the project.
        #
        # @param app [Hanami::Configuration::App] a Hanami application
        #
        # @since 0.9.0
        # @api private
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def self.resolve(app)
          config    = app.configuration
          namespace = app.namespace

          unless namespace.const_defined?('Controller', false)
            controller = Hanami::Controller.duplicate(namespace) do
              handle_exceptions config.handle_exceptions
              public_directory  Hanami.public_directory
              default_request_format config.default_request_format
              default_response_format config.default_response_format
              default_headers(
                Hanami::Config::Security::X_FRAME_OPTIONS_HEADER         => config.security.x_frame_options,
                Hanami::Config::Security::X_CONTENT_TYPE_OPTIONS_HEADER  => config.security.x_content_type_options,
                Hanami::Config::Security::X_XSS_PROTECTION_HEADER        => config.security.x_xss_protection,
                Hanami::Config::Security::CONTENT_SECURITY_POLICY_HEADER => config.security.content_security_policy
              )
              default_headers[STRICT_TRANSPORT_SECURITY_HEADER] = STRICT_TRANSPORT_SECURITY_DEFAULT_VALUE if config.force_ssl

              if config.cookies.enabled?
                require 'hanami/action/cookies'
                prepare { include Hanami::Action::Cookies }
                cookies config.cookies.default_options
              end

              if config.sessions.enabled?
                prepare do
                  include Hanami::Action::Session
                  include Hanami::Action::CSRFProtection
                end
              end

              prepare { include Hanami::Action::RoutingHelpers }

              config.controller.__apply(self)
            end

            namespace.const_set('Controller', controller)
          end

          Components.resolved "#{app.app_name}.controller", namespace.const_get('Controller').configuration
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
