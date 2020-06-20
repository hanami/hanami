require 'rack/common_logger'
require 'hanami/utils/hash'

module Hanami
  # Rack logger for Hanami.app
  #
  # @since 1.0.0
  # @api private
  class CommonLogger < Rack::CommonLogger
    private

    # @since 1.0.0
    # @api private
    HTTP_VERSION         = 'HTTP_VERSION'.freeze

    # @since 1.0.0
    # @api private
    REQUEST_METHOD       = 'REQUEST_METHOD'.freeze

    # @since 1.0.0
    # @api private
    HTTP_X_FORWARDED_FOR = 'HTTP_X_FORWARDED_FOR'.freeze

    # @since 1.0.0
    # @api private
    REMOTE_ADDR          = 'REMOTE_ADDR'.freeze

    # @since 1.0.0
    # @api private
    SCRIPT_NAME          = 'SCRIPT_NAME'.freeze

    # @since 1.0.0
    # @api private
    PATH_INFO            = 'PATH_INFO'.freeze

    # @since 1.0.0
    # @api private
    RACK_ERRORS          = 'rack.errors'.freeze

    # @since 1.1.0
    # @api private
    QUERY_HASH           = 'rack.request.query_hash'.freeze

    # @since 1.1.0
    # @api private
    FORM_HASH            = 'rack.request.form_hash'.freeze

    # @since 1.3.0
    # @api private
    ROUTER_PARAMS        = 'router.params'.freeze

    # @since 1.0.0
    # @api private
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def log(env, status, header, began_at)
      now    = Rack::Utils.clock_time
      length = extract_content_length(header)

      msg = Hash[
        http:    env[HTTP_VERSION],
        verb:    env[REQUEST_METHOD],
        status:  status.to_s[0..3],
        ip:      env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR],
        path:    env[SCRIPT_NAME] + env[PATH_INFO].to_s,
        length:  length,
        params:  extract_params(env),
        elapsed: now - began_at
      ]

      logger = @logger || env[RACK_ERRORS]
      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      if logger.respond_to?(:write)
        logger.write(msg)
      else
        logger.info(msg)
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    # @since 1.1.0
    # @api private
    def extract_params(env)
      result = env.fetch(QUERY_HASH, {})
      result.merge!(env.fetch(FORM_HASH, {}))
      result.merge!(Utils::Hash.deep_stringify(env.fetch(ROUTER_PARAMS, {})))
      result
    end
  end
end
