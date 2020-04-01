# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami container configuration
    #
    # @since 2.0.0
    class Container
      attr_reader :options

      def initialize(options)
        @options = options
      end
    end
  end
end
