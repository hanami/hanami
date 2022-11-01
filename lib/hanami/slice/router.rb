# frozen_string_literal: true

require "hanami/router"
require_relative "routing/middleware/stack"

module Hanami
  class Slice
    # `Hanami::Router` subclass with enhancements for use within Hanami apps.
    #
    # This is loaded from Hanami apps and slices and made available as their
    # {Hanami::Slice::ClassMethods#router router}.
    #
    # @api private
    # @since 2.0.0
    class Router < ::Hanami::Router
      # @api private
      attr_reader :middleware_stack

      # @api private
      # @since 2.0.0
      def initialize(routes:, middleware_stack: Routing::Middleware::Stack.new, **kwargs, &blk)
        @middleware_stack = middleware_stack
        instance_eval(&blk)
        super(**kwargs, &routes)
      end

      # @api private
      # @since 2.0.0
      def freeze
        return self if frozen?

        remove_instance_variable(:@middleware_stack)
        super
      end

      # @api private
      # @since 2.0.0
      def use(...)
        middleware_stack.use(...)
      end

      # @api private
      # @since 2.0.0
      def scope(*args, &blk)
        middleware_stack.with(args.first) do
          super
        end
      end

      # Yields a block for routes to resolve their action components from the given slice.
      #
      # An optional URL prefix may be supplied with `at:`.
      #
      # @example
      #   # config/routes.rb
      #
      #   module MyApp
      #     class Routes < Hanami::Routes
      #       slice :admin, at: "/admin" do
      #         # Will route to the "actions.posts.index" component in Admin::Slice
      #         get "posts", to: "posts.index"
      #       end
      #     end
      #   end
      #
      # @param slice_name [Symbol] the slice's name
      # @param at [String, nil] optional URL prefix for the routes
      #
      # @api public
      # @since 2.0.0
      def slice(slice_name, at:, &blk)
        blk ||= @resolver.find_slice(slice_name).routes

        prev_resolver = @resolver
        @resolver = @resolver.to_slice(slice_name)

        scope(prefixed_path(at), &blk)
      ensure
        @resolver = prev_resolver
      end

      # @api private
      # @since 2.0.0
      def to_rack_app
        middleware_stack.to_rack_app(self)
      end
    end
  end
end
