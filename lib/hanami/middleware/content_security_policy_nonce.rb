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
      end

      # @api private
      # @since x.x.x
      def call(env)
        return @app.call(env) unless Hanami.app.config.actions.content_security_policy?

        args = nonce_generator.arity == 1 ? [Rack::Request.new(env)] : []
        request_nonce = nonce_generator.call(*args)

        env[CONTENT_SECURITY_POLICY_NONCE_REQUEST_KEY] = request_nonce

        _, headers, _ = response = @app.call(env)

        headers["Content-Security-Policy"] = sub_nonce(headers["Content-Security-Policy"], request_nonce)

        response
      end

      private

      def nonce_generator
        Hanami.app.config.actions.content_security_policy_nonce_generator
      end

      def sub_nonce(string, nonce)
        string&.gsub("'nonce'", "'nonce-#{nonce}'")
      end
    end
  end
end
