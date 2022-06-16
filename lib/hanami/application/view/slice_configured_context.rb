# frozen_string_literal: true

require "hanami/view"

module Hanami
  class Application
    class View < Hanami::View
      # Provides slice-specific configuration and behavior for any view context class
      # defined within a slice's module namespace.
      #
      # @api private
      # @since 2.0.0
      class SliceConfiguredContext < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(context_class)
          define_new

          # TODO: make this conditional, since helpers may not always be loaded?
          require "hanami/helpers/form_helper"
          context_class.include(Hanami::Helpers::FormHelper)
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        # Defines a {.new} method on the context class that resolves key components from
        # the application container and provides them to {#initialize} as injected
        # dependencies.
        #
        # This includes the following application components:
        #
        #   - the configured inflector as `inflector`
        #   - "settings" from the application container as `settings`
        #   - "routes" from the application container as `routes`
        #   - "assets" from the application container as `assets`
        def define_new
          inflector = slice.inflector
          resolve_settings = method(:resolve_settings)
          resolve_routes = method(:resolve_routes)
          resolve_assets = method(:resolve_assets)
          resolve_helpers = method(:resolve_helpers)

          define_method :new do |**kwargs|
            kwargs[:inflector] ||= inflector
            kwargs[:settings] ||= resolve_settings.()
            kwargs[:routes] ||= resolve_routes.()
            kwargs[:assets] ||= resolve_assets.()
            kwargs[:helpers] ||= resolve_helpers.()

            super(**kwargs)
          end
        end

        def resolve_settings
          slice.application[:settings] if slice.application.key?(:settings)
        end

        def resolve_routes
          slice.application[:routes_helper] if slice.application.key?(:routes_helper)
        end

        def resolve_assets
          slice.application[:assets] if slice.application.key?(:assets)
        end

        def resolve_helpers
          slice.application[:helpers] if slice.application.key?(:helpers)
        end
      end
    end
  end
end
