# frozen_string_literal: true

module Hanami
  # HTTP/2 Early Hints Rack middleware
  #
  # It sends extra responses **before** the main reponse is sent.
  # These extra responses are HTTP/2 Early Hints (103).
  # They specify the web assets (javascripts, stylesheets, etc..) to be "pushed",
  # so modern browsers pre-fetch them in parallel with the main HTTP response.
  #
  # @see https://tools.ietf.org/html/draft-ietf-httpbis-early-hints-05
  #
  # @since 1.2.0
  # @api private
  class EarlyHints
    # @since 1.2.0
    # @api private
    class NotSupportedByServerError < ::StandardError
      # @since 1.2.0
      # @api private
      def initialize
        super("Current Ruby server doesn't support Early Hints.\nPlease make sure to use a web server with Early Hints enabled (only Puma for now).")
      end
    end

    # @since 1.2.0
    # @api private
    def initialize(app)
      @app = app
    end

    # @param env [Hash] Rack env
    #
    # @return [Array,Rack::Response] a Rack response
    #
    # @raise [Hanami::EarlyHints::NotSupportedByServerError] if the current Ruby
    #   server doesn't support Early Hints
    #
    # @since 1.2.0
    # @api private
    def call(env)
      @app.call(env).tap do
        send_early_hints(env)
      end
    end

    private

    # Pushing a lot of assets may exceed the limit of HTTP headers of a single
    # Early Hints (103) response.
    #
    # For this reason we send multiple Early Hints (103) responses for each `n`
    # assets. We call this `n` number `BATCH_SIZE`.
    #
    # If the current page needs to push 23 assets, it will send 3 Early Hints
    # (103) responses:
    #
    #   1. Response #1: 10 assets
    #   2. Response #2: 10 assets
    #   3. Response #3: 3 assets
    #
    # @since 1.2.0
    # @api private
    BATCH_SIZE = 10

    # Rack servers that support Early Hints (only Puma for now),
    # inject an object into the Rack env to send multiple Early Hints (103)
    # responses.
    #
    # @since 1.2.0
    # @api private
    #
    # @see https://github.com/puma/puma/pull/1403
    RACK_EARLY_HINTS_ENV_KEY = "rack.early_hints"

    # This cache key is used by `hanami-assets` to collect the assets that are
    # eligible to be pushed.
    #
    # It stores these values in a thread-local variable.
    #
    # NOTE: if changing this key here, it MUST be changed into `hanami-assets` as well
    #
    # @since 1.2.0
    # @api private
    CACHE_KEY = :__hanami_assets

    # Tries to send multiple Early Hints (103) HTTP responses, if there are
    # assets eligible.
    #
    # @param env [Hash] Rack env
    #
    # @raise [Hanami::EarlyHints::NotSupportedByServerError] if the current Ruby
    #   server doesn't support Early Hints
    #
    # @since 1.2.0
    # @api private
    def send_early_hints(env)
      return if Thread.current[CACHE_KEY].nil?

      Thread.current[CACHE_KEY].each_slice(BATCH_SIZE) do |slice|
        link = slice.map do |asset, options|
          ret = %(<#{asset}>; rel=preload)
          ret += "; as=#{options[:as]}" unless options[:as].nil?
          ret += "; crossorigin" if options[:crossorigin]
          ret
        end.join("\n")

        send_early_hints_response(env, link)
      end
    end

    # Tries to send an Early Hints (103) HTTP response for a batch of assets
    #
    # @param env [Hash] Rack env
    # @param link [String] the serialized HTTP `Link` headers
    #
    # @raise [Hanami::EarlyHints::NotSupportedByServerError] if the current Ruby
    #   server doesn't support Early Hints
    #
    # @since 1.2.0
    # @api private
    def send_early_hints_response(env, link)
      env[RACK_EARLY_HINTS_ENV_KEY].call("Link" => link)
    rescue NoMethodError => exception
      raise exception if env.key?(RACK_EARLY_HINTS_ENV_KEY)
      raise NotSupportedByServerError
    end
  end
end
