# frozen_string_literal: true

require "hanami/utils/string"
require "hanami/utils/class"

module Hanami
  class Configuration
    # Hanami configuration for HTTP sessions
    #
    # @since 2.0.0
    class Sessions
      def self.null
        NULL_STORAGE
      end

      attr_reader :storage, :options

      def initialize(*args)
        args = Array(args.dup).flatten

        @storage = args.shift
        @options = args.shift || {}
      end

      def enabled?
        storage != NULL_STORAGE
      end

      def middleware
        [[storage_middleware, options]]
      end

      private

      NULL_STORAGE = :null
      private_constant :NULL_STORAGE

      def storage_middleware
        require_storage

        name = Utils::String.classify(storage)
        Utils::Class.load!(name, Rack::Session)
      end

      def require_storage
        require "rack/session/#{storage}"
      end
    end
  end
end
