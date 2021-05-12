# frozen_string_literal: true

require "hanami/utils/string"
require "hanami/utils/class"

module Hanami
  class Configuration
    # Hanami configuration for HTTP sessions
    #
    # @since 2.0.0
    class Sessions
      NULL_SESSION_OPTION = :null
      private_constant :NULL_SESSION_OPTION

      def self.null
        self.class.new(NULL_SESSION_OPTION)
      end

      attr_reader :storage, :options

      def initialize(*args)
        storage, options, = Array(args.dup).flatten

        @storage = storage
        @options = options || {}
      end

      def enabled?
        storage != NULL_SESSION_OPTION
      end

      def middleware
        [[storage_middleware, options]]
      end

      private

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
