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
      def initialize(routes:, stack: Routing::Middleware::Stack.new, **kwargs, &blk)
        @stack = stack
        instance_eval(&blk)
        super(**kwargs, &routes)
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
        @stack.use(middleware, *args, &blk)
      end

      # @since 2.0.0
      # @api private
      def scope(*args, &blk)
        @stack.with(args.first) do
          super
        end
      end

      # @since 2.0.0
      def slice(name, at:, &blk)
        path = prefixed_path(at)
        @resolver.register_slice_at_path(name, path)

        scope(path, &blk)
      end

      # @since 2.0.0
      # @api private
      def to_rack_app
        return self if @stack.empty?

        @stack.to_rack_app(self)
      end
    end
  end
end
