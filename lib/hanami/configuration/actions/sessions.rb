# frozen_string_literal: true

require "dry/core/constants"
require "hanami/utils/string"
require "hanami/utils/class"

module Hanami
  class Configuration
    class Actions
      # Configuration for HTTP sessions in Hanami actions
      #
      # @since 2.0.0
      class Sessions
        attr_reader :storage, :options

        def initialize(storage = nil, *options)
          @storage = storage
          @options = options
        end

        def enabled?
          !storage.nil?
        end

        def middleware
          return [] if !enabled?

          [[storage_middleware, options]]
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
