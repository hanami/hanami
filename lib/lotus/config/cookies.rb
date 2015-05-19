module Lotus
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
      #
      # @since x.x.x
      # @api private
      #
      # @see https://github.com/rack/rack/blob/master/lib/rack/utils.rb #set_cookie_header!
      # @see https://www.owasp.org/index.php/HttpOnly
      #
      # @example with boolean option
      #
      #  require 'lotus/config/cookies'
      #
      #  cookies_config = Lotus::Config::Cookies.new(true)
      #  # => #<Lotus::Config::Cookies:0x007fb902c55978 @options=true, @default_options={:httponly=>true}>
      #  cookies_config.enabled? # => true
      #
      #  cookies_config = Lotus::Config::Cookies.new(false)
      #  # => #<Lotus::Config::Cookies:0x007fb902c55978 @options=false, @default_options={:httponly=>true}>
      #  cookies_config.enabled? # => false
      #
      # @example with hash option
      #
      #  require 'lotus/config/cookies'
      #
      #  cookies_config = Lotus::Config::Cookies.new(max_age: true)
      #  # => #<Lotus::Config::Cookies:0x007fb902c37f40 @options={:max_age=>true}, @default_options={:httponly=>true, :max_age=>true}>
      #  cookies_config.enabled? # => true
      def initialize(options = {})
        @options         = options
        @default_options = { httponly: true }
        @default_options.merge!(options) if options.is_a? Hash
      end

      # Return if cookies are enabled
      #
      # @return [TrueClass, FalseClass] enabled cookies
      #
      # @since 0.3.0
      # @api private
      def enabled?
        @options.respond_to?(:empty?) ? !@options.empty? : @options
      end
    end
  end
end
