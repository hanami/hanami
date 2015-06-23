require 'securerandom'

module Lotus
  module Action
    # Invalid CSRF Token
    #
    # @since 0.4.0
    class InvalidCSRFTokenError < ::StandardError
    end

    # CSRF Protection
    #
    # This security mechanism is enabled automatically if sessions are turned on.
    #
    # It stores a "challenge" token in session. For each "state changing request"
    # (eg. <tt>POST</tt>, <tt>PATCH</tt> etc..), we should send a special param:
    # <tt>_csrf_token</tt>.
    #
    # If the param matches with the challenge token, the flow can continue.
    # Otherwise the application detects an attack attempt, it reset the session
    # and <tt>Lotus::Action::InvalidCSRFTokenError</tt> is raised.
    #
    # We can specify a custom handling strategy, by overriding <tt>#handle_invalid_csrf_token</tt>.
    #
    # Form helper (<tt>#form_for</tt>) automatically sets a hidden field with the
    # correct token. A special view method (<tt>#csrf_token</tt>) is available in
    # case the form markup is manually crafted.
    #
    # We can disable this check on action basis, by overriding <tt>#verify_csrf_token?</tt>.
    #
    # @since 0.4.0
    #
    # @see https://www.owasp.org/index.php/Cross-Site_Request_Forgery_%28CSRF%29
    # @see https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
    #
    # @example Custom Handling
    #   module Web::Controllers::Books
    #     class Create
    #       include Web::Action
    #
    #       def call(params)
    #         # ...
    #       end
    #
    #       private
    #
    #       def handle_invalid_csrf_token
    #         Web::Logger.warn "CSRF attack: expected #{ session[:_csrf_token] }, was #{ params[:_csrf_token] }"
    #         # manual handling
    #       end
    #     end
    #   end
    #
    # @example Bypass Security Check
    #   module Web::Controllers::Books
    #     class Create
    #       include Web::Action
    #
    #       def call(params)
    #         # ...
    #       end
    #
    #       private
    #
    #       def verify_csrf_token?
    #         false
    #       end
    #     end
    #   end
    module CSRFProtection
      # Session and params key for CSRF token.
      #
      # This key is shared with <tt>lotus-controller</tt> and <tt>lotus-helpers</tt>
      #
      # @since 0.4.0
      # @api private
      CSRF_TOKEN = :_csrf_token

      # Idempotent HTTP methods
      #
      # By default, the check isn't performed if the request method is included
      # in this list.
      #
      # @since 0.4.0
      # @api private
      IDEMPOTENT_HTTP_METHODS = Hash[
        'GET'     => true,
        'HEAD'    => true,
        'TRACE'   => true,
        'OPTIONS' => true
      ].freeze

      # @since 0.4.0
      # @api private
      def self.included(action)
        action.class_eval do
          before :set_csrf_token, :verify_csrf_token
        end unless Lotus.env?(:test)
      end

      private
      # Set CSRF Token in session
      #
      # @since 0.4.0
      # @api private
      def set_csrf_token
        session[CSRF_TOKEN] ||= generate_csrf_token
      end

      # Verify if CSRF token from params, matches the one stored in session.
      # If not, it raises an error.
      #
      # Don't override this method.
      #
      # To bypass the security check, please override <tt>#verify_csrf_token?</tt>.
      # For custom handling of an attack, please override <tt>#handle_invalid_csrf_token</tt>.
      #
      # @since 0.4.0
      # @api private
      def verify_csrf_token
        handle_invalid_csrf_token if invalid_csrf_token?
      end

      # Verify if CSRF token from params, matches the one stored in session.
      #
      # Don't override this method.
      #
      # @since 0.4.0
      # @api private
      def invalid_csrf_token?
        verify_csrf_token? &&
          session[CSRF_TOKEN] != params[CSRF_TOKEN]
      end

      # Generates a random CSRF Token
      #
      # @since 0.4.0
      # @api private
      def generate_csrf_token
        SecureRandom.hex(32)
      end

      # Decide if perform the check or not.
      #
      # Override and return <tt>false</tt> if you want to bypass security check.
      #
      # @since 0.4.0
      def verify_csrf_token?
        !IDEMPOTENT_HTTP_METHODS[request_method]
      end

      # Handle CSRF attack.
      #
      # The default policy resets the session and raises an exception.
      #
      # Override this method, for custom handling.
      #
      # @raise [Lotus::Action::InvalidCSRFTokenError]
      #
      # @since 0.4.0
      def handle_invalid_csrf_token
        session.clear
        raise InvalidCSRFTokenError.new
      end
    end
  end
end
