# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami application configured Rack middleware
    #
    # @since 2.0.0
    class Middleware
      def initialize
        @stack = []
      end

      def use(middleware, *args, &block)
        stack.push([middleware, args, block].compact)
      end

      attr_reader :stack
    end
  end
end
