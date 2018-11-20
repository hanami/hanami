# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami configuration for HTTP cookies
    #
    # @since 2.0.0
    class Cookies
      def self.null
        { null: true }
      end

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def enabled?
        options != self.class.null
      end
    end
  end
end
