# frozen_string_literal: true

require "hanami/router"
require_relative "routing/middleware/stack"

module Hanami
  class Slice
    # Hanami application router
    # @since 2.0.0
    class Router < ::Hanami::Router
      # @api private
      attr_reader :middleware_stack

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
      def use(...)
        middleware_stack.use(...)
      end

      # @since 2.0.0
      # @api private
      def scope(*args, &blk)
        middleware_stack.with(args.first) do
          super
        end
      end

      # @since 2.0.0
      def slice(slice_name, at:, &blk)
        blk ||= @resolver.find_slice(slice_name).routes

        prev_resolver = @resolver
        @resolver = @resolver.to_slice(slice_name)

        scope(prefixed_path(at), &blk)
      ensure
        @resolver = prev_resolver
      end

      # @since 2.0.0
      # @api private
      def to_rack_app
        middleware_stack.to_rack_app(self)
      end
    end
  end
end
