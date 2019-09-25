# frozen_string_literal: true

require "hanami/router"

module Hanami
  module Web
    # TODO: need to think about the best place to hang this logic now that it
    # may reside within hanami itself
    class Router < Hanami::Router
      attr_reader :middlewares

      def initialize(application:, **options, &block)
        @application = application
        @options = options
        @middlewares = []

        super(**options, &nil)
        instance_exec(application, &block) if block
        freeze overridden: true
      end

      # Do nothing when the superclass calls freeze during its own initialize
      # (we need to do it later, after our instance_exec of the routes block)
      def freeze(overridden: false)
        super() if overridden
      end

      # Ensure we always return a rack-conformant result (sometimes we get a
      # Hanami::Action::Response here, when we actually want the standard rack
      # 3-element array)
      def call(*)
        super.to_a
      end

      def use(*args, &block)
        middlewares << (args << block)
      end

      def mount(app, at:, host: nil, &block)
        if app.is_a?(Symbol) && (sliced_resolver = @endpoint_resolver.sliced(app))
          sliced_router = self.class.new(
            application: @application.slices[app],
            **@options,
            endpoint_resolver: sliced_resolver,
            &block
          )

          super(sliced_router, at: at, host: host)
        else
          super(app, at: at, host: host)
        end
      end

      # Allow router objects to be mounted within themselves
      def match?(env)
        match_path?(env)
      end
    end
  end
end
