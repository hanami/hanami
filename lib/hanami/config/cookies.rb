module Hanami
  module Config
    # Cookies configuration
    #
    # @since 0.3.0
    # @api private
    class Cookies

      # Return the routes for this application
      #
      # @return [Hash] options for cookies
      #
      # @since 0.3.0
      # @api private
      attr_reader :default_options

      # Cookies configuration
      #
      # httponly option enabled by default.
      # Prevent attackers to steal cookies via JavaScript,
      # Eg. alert(document.cookie) will fail
      #
      # @param options [Hash, TrueClass, FalseClass] optional cookies options
      # @param configuration [Hanami::Configuration] the application configuration
      #
      # @since 0.3.0
      # @api private
      #
      # @see https://github.com/rack/rack/blob/master/lib/rack/utils.rb #set_cookie_header!
      # @see https://www.owasp.org/index.php/HttpOnly
      #
      # @example Enable cookies with boolean
      #   module Web
      #     class Application < Hanami::Application
      #       configure do
      #         # ...
      #         cookies true
      #       end
      #     end
      #   end
      #
      # @example Enable cookies with options
      #   module Web
      #     class Application < Hanami::Application
      #       configure do
      #         # ...
      #         cookies max_age: 300
      #       end
      #     end
      #   end
      def initialize(configuration, options = {})
        @options         = options
        @default_options = { httponly: true, secure: configuration.ssl? }
        @default_options.merge!(options) if options.is_a?(::Hash)
      end

      # Return if cookies are enabled
      #
      # @return [TrueClass, FalseClass] enabled cookies
      #
      # @since 0.3.0
      # @api private
      def enabled?
        @options.respond_to?(:empty?) ? !@options.empty? : !!@options
      end
    end
  end
end
