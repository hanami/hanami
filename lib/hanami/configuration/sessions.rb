# frozen_string_literal: true

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

      NULL_STORAGE = :null
      private_constant :NULL_STORAGE
    end
  end
end
