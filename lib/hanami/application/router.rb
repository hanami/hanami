# frozen_string_literal: true

require "hanami/router"
require "hanami/application/routing/middleware/stack"

module Hanami
  class Application
    # Hanami application router
    # @since 2.0.0
    class Router < ::Hanami::Router
      # @since 2.0.0
      # @api private
      def initialize(stack:, **kwargs, &blk)
        @stack = stack
        super(**kwargs, &blk)
      end

      # @since 2.0.0
      # @api private
      def freeze
        return self if frozen?

        remove_instance_variable(:@stack)
        super
      end

      # @since 2.0.0
      # @api private
      def use(middleware, *args, &blk)
        @stack.use(middleware, args, &blk)
      end

      # @since 2.0.0
      # @api private
      def scope(*args, **kwargs, &blk)
        @stack.with(args.first) do
          super
        end
      end

      # @since 2.0.0
      def slice(name, at:, &blk)
        path = prefixed_path(at)
        @resolver.register_slice(path, name)

        scope(path, &blk)
      end
    end
  end
end
