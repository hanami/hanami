# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # Provides slice-specific configuration and behavior for any view context class defined within
      # a slice's module namespace.
      #
      # @api public
      # @since 2.1.0
      class SliceConfiguredContext < Module
        attr_reader :slice

        # @api private
        # @since 2.1.0
        def initialize(slice)
          super()
          @slice = slice
          @components = {}.freeze
        end

        # @api private
        # @since 2.1.0
        def extended(_context_class)
          define_new
        end

        # @api public
        # @since 2.1.0
        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        # Defines a {.new} method on the context class that resolves key components from the app
        # container and provides them to {#initialize} as injected dependencies.
        #
        # This includes the following app components:
        #   - the configured inflector as `inflector`
        #   - "routes" from the app container as `routes`
        #   - "assets" from the slice container as `assets`
        #   - "i18n" from the slice container as `i18n`
        def define_new
          inflector = slice.inflector
          resolve_routes = method(:resolve_routes)
          resolve_assets = method(:resolve_assets)
          resolve_i18n = method(:resolve_i18n)

          define_method :new do |**kwargs|
            kwargs[:inflector] ||= inflector
            kwargs[:routes] ||= resolve_routes.()
            kwargs[:assets] ||= resolve_assets.()
            kwargs[:i18n] ||= resolve_i18n.()

            super(**kwargs)
          end
        end

        # Resolves from the app, not the slice, because a slice defining its own routes registers
        # its own "routes" component, which knows only that slice's names and none of the prefix it
        # is mounted at. Actions resolve the app's helper, so this keeps a view and an action in the
        # same slice in agreement.
        def resolve_routes
          resolve_component(slice.app, "routes")
        end

        def resolve_assets
          resolve_component(slice, "assets")
        end

        def resolve_i18n
          resolve_component(slice, "i18n")
        end

        # Returns the component registered under the key, or nil if there is none.
        #
        # A context is built for every view rendered, so the answer is kept once it can no longer
        # change.
        def resolve_component(source, key)
          return @components[key] if @components.key?(key)

          component = source[key] if source.key?(key)
          @components = @components.merge(key => component).freeze if settled?(source)

          component
        end

        # Components are settled once their slice is booted, except in the test env, where they can
        # be stubbed at any time.
        def settled?(source)
          source.booted? && !Hanami.env?(:test)
        end
      end
    end
  end
end
