# frozen_string_literal: true

require "rack"
require "securerandom"
require_relative "../constants"

module Hanami
  module Middleware
    # Generates a random per request nonce value like `mSMnSwfVZVe+LyQy1SPCGw==`, stores it as
    # `"hanami.content_security_policy_nonce"` in the Rack environment, and replaces all occurrences
    # of `'nonce'` in the `Content-Security-Policy header with the actual nonce value for the
    # request, e.g. `'nonce-mSMnSwfVZVe+LyQy1SPCGw=='`.
    #
    # @see Hanami::Middleware::ContentSecurityPolicyNonce
    #
    # @api private
    # @since x.x.x
    class ContentSecurityPolicyNonce
      # @api private
      # @since x.x.x
      def initialize(app)
        @app = app
        @nonce = random_nonce
      end

      # @api private
      # @since x.x.x
      def call(env)
        return @app.call(env) unless Hanami.app.config.actions.content_security_policy?

        env[CONTENT_SECURITY_POLICY_NONCE_REQUEST_KEY] = @nonce
        @app.call(env).tap do |response|
          headers = response[1]
          headers["Content-Security-Policy"] = sub_nonce headers["Content-Security-Policy"]
        end
      end

      private

      def random_nonce
        SecureRandom.urlsafe_base64(16)
      end

      def sub_nonce(string)
        string&.gsub("'nonce'", "'nonce-#{@nonce}'")
      end
    end
  end
end
