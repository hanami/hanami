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
      def initialize(routes:, middleware_stack: Routing::Middleware::Stack.new, **kwargs, &blk)
        @middleware_stack = middleware_stack
        instance_eval(&blk)
        super(**kwargs, &routes)
      end

      # @since 2.0.0
      # @api private
      def freeze
        return self if frozen?

        remove_instance_variable(:@middleware_stack)
        super
      end

      # @since 2.0.0
      # @api private
      def use(middleware, *args, &blk)
        @middleware_stack.use(middleware, *args, &blk)
      end

      # @since 2.0.0
      # @api private
      def scope(*args, &blk)
        @middleware_stack.with(args.first) do
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
        return self if @middleware_stack.empty?

        @middleware_stack.to_rack_app(self)
      end
    end
  end
end
