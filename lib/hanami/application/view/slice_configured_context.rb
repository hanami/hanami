# frozen_string_literal: true

require "hanami/view"

module Hanami
  class Application
    class View < Hanami::View
      # @api private
      class SliceConfiguredContext < Module
        attr_reader :slice

        def initialize(slice)
          @slice = slice
        end

        def extended(view_class)
          define_new
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        def define_new
          inflector = slice.inflector
          resolve_settings = method(:resolve_settings)
          resolve_routes = method(:resolve_routes)
          resolve_assets = method(:resolve_assets)

          define_method :new do |**kwargs|
            kwargs[:inflector] ||= inflector
            kwargs[:settings] ||= resolve_settings.()
            kwargs[:routes] ||= resolve_routes.()
            kwargs[:assets] ||= resolve_assets.()

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
      end
    end
  end
end
