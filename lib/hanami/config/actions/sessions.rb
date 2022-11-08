# frozen_string_literal: true

require "hanami/utils/string"
require "hanami/utils/class"

module Hanami
  class Config
    class Actions
      # Config for HTTP session middleware in Hanami actions.
      #
      # @api public
      # @since 2.0.0
      class Sessions
        # Returns the configured session storage
        #
        # @return [Symbol]
        #
        # @api public
        # @since 2.0.0
        attr_reader :storage

        # Returns the configured session storage options
        #
        # @return [Array]
        #
        # @api public
        # @since 2.0.0
        attr_reader :options

        # Returns a new `Sessions`.
        #
        # You should not need to initialize this class directly. Instead use
        # {Hanami::Config::Actions#sessions=}.
        #
        # @example
        #   config.actions.sessions = :cookie, {secret: "xyz"}
        #
        # @api private
        # @since 2.0.0
        def initialize(storage = nil, *options)
          @storage = storage
          @options = options
        end

        # Returns true if sessions have been enabled.
        #
        # @return [Boolean]
        #
        # @api public
        # @since 2.0.0
        def enabled?
          !storage.nil?
        end

        # Returns an array of the session storage middleware name and its options, or an empty array
        # if sessions have not been enabled.
        #
        # @return [Array<(Symbol, Array)>]
        #
        # @api public
        # @since 2.0.0
        def middleware
          return [] unless enabled?

          [storage_middleware, options].flatten(1)
        end

        private

        def storage_middleware
          require_storage

          name = Utils::String.classify(storage)
          Utils::Class.load!(name, ::Rack::Session)
        end

        def require_storage
          require "rack/session/#{storage}"
        end
      end
    end
  end
end
