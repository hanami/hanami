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

      def each(&blk)
        stack.each(&blk)
      end

      def use(middleware, *args)
        stack.push([middleware, *args])
      end

      private

      attr_reader :stack
    end
  end
end
