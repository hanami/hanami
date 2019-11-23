# frozen_string_literal: true

require "hanami/router"
require "rack"

module Hanami
  class Application
    # Hanami application router
    # @since 2.0.0
    class Router < Hanami::Router
      def initialize(**options, &block)
        @options = options
        @middlewares = []
        super
        @rack_app = build_rack_app
      end

      def use(*args, &block)
        @middlewares << (args << block)
      end

      # rubocop:disable Metrics/MethodLength
      def mount(app, at:, host: nil, &block)
        if app.is_a?(Symbol)
          # TODO: I wonder if this is the actual behaviour we want...
          raise "Slices can only be mounted from top-level of routes" unless @context.respond_to?(:slices)

          # TODO: store slices in a way that's more efficient for lookup
          slice = @context.slices[app]

          # TODO: real exception class
          raise "Slice +#{app}+ not found" unless slice

          slice_router = self.class.new(
            **@options,
            context: slice,
            endpoint_resolver: @endpoint_resolver.with_container(slice),
            &block
          )

          super(slice_router, at: at, host: host)
        else
          super(app, at: at, host: host)
        end
      end
      # rubocop:enable Metrics/MethodLength

      alias call_router call
      private :call_router # rubocop:disable Style/AccessModifierDeclarations

      def call(env)
        @rack_app.call(env)
      end

      private

      def build_rack_app
        middlewares = @middlewares
        app = method(:call_router)

        Rack::Builder.new do
          middlewares.each do |(*middleware, block)|
            use(*middleware, &block)
          end

          run app
        end
      end
    end
  end
end
