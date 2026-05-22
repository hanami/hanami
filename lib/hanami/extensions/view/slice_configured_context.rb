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
        #   - "assets" from the app container as `assets`
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

        def resolve_routes
          slice["routes"] if slice.key?("routes")
        end

        def resolve_assets
          slice["assets"] if slice.key?("assets")
        end

        def resolve_i18n
          slice["i18n"] if slice.key?("i18n")
        end
      end
    end
  end
end
