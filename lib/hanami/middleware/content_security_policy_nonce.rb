# frozen_string_literal: true

require "rack"
require "securerandom"

module Hanami
  module Middleware
    # Generate a random per request nonce value like `A12OggyZ`, write
    # it to `hanami.content_security_policy_nonce` and replace all
    # occurrences of `'nonce'` in the Content-Security-Policy header
    # with `'nonce-A12OggyZ'`.
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
        if Hanami.app.config.actions.content_security_policy == false
          @app.call(env)
        else
          env["hanami.content_security_policy_nonce"] = @nonce
          @app.call(env).tap do |response|
            headers = response[1]
            headers["Content-Security-Policy"] = sub_nonce headers["Content-Security-Policy"]
          end
        end
      end

      private

      def random_nonce
        SecureRandom.alphanumeric(8)
      end

      def sub_nonce(string)
        string&.gsub("'nonce'", "'nonce-#{@nonce}'")
      end
    end
  end
end
