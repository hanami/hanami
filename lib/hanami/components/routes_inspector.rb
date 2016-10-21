require 'hanami/routing/default'
require_relative './app/routes'

module Hanami
  module Components
    # Project's routes inspector
    #
    # @since x.x.x
    # @api private
    class RoutesInspector
      # @param configuration [Hanami::Configuration]
      #
      # @since x.x.x
      # @api private
      def initialize(configuration)
        @configuration = configuration
      end

      # Returns a printable version of the project routes
      #
      # @return [String] printable routes
      #
      # @since x.x.x
      # @api private
      def inspect
        routes.map do |r|
          r.inspector.to_s
        end.join("\n")
      end

      private

      # @since x.x.x
      # @api private
      attr_reader :configuration

      # @since x.x.x
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

      # @since x.x.x
      # @api private
      def hanami_app?(klass)
        klass.ancestors.include?(Hanami::Application)
      end

      # @since x.x.x
      # @api private
      def resolve_hanami_app_router(app)
        App::Routes.application_routes(app)
      end

      # @since x.x.x
      # @api private
      def resolve_rack_app_router(app)
        Hanami::Router.new do
          mount app.name, at: app.path_prefix
        end
      end
    end
  end
end
