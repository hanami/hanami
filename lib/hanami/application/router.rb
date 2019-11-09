# frozen_string_literal: true

require "hanami/router"

module Hanami
  class Application
    class Router < Hanami::Router
      def initialize(**options, &block)
        @options = options
        super
      end

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
    end
  end
end
