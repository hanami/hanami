require 'hanami/routing/default'
require_relative './app/routes'

module Hanami
  # @since 0.9.0
  # @api private
  module Components
    # Project's routes inspector
    #
    # @since 0.9.0
    # @api private
    class RoutesInspector
      # @param configuration [Hanami::Configuration]
      #
      # @since 0.9.0
      # @api private
      def initialize(configuration)
        @configuration = configuration
      end

      # Returns a printable version of the project routes
      #
      # @return [String] printable routes
      #
      # @since 0.9.0
      # @api private
      def inspect
        routes.map do |r|
          r.inspector.to_s
        end.join("\n")
      end

      private

      # @since 0.9.0
      # @api private
      attr_reader :configuration

      # @since 0.9.0
      # @api private
      def routes
        configuration.mounted.each_with_object([]) do |(klass, app), result|
          result << if hanami_app?(klass)
                      resolve_hanami_app_router(app)
                    else
                      resolve_rack_app_router(app)
                    end
        end
      end

      # @since 0.9.0
      # @api private
      def hanami_app?(klass)
        klass.ancestors.include?(Hanami::Application)
      end

      # @since 0.9.0
      # @api private
      def resolve_hanami_app_router(app)
        App::Routes.application_routes(app)
      end

      # @since 0.9.0
      # @api private
      def resolve_rack_app_router(app)
        Hanami::Router.new do
          mount app.name, at: app.path_prefix
        end
      end
    end
  end
end
