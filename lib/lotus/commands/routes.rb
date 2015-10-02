module Lotus
  module Commands
    # Display application/container routes.
    #
    # It is run with:
    #
    #   `bundle exec lotus routes`
    #
    # @since 0.1.0
    # @api private
    class Routes
      # @param options [Hash] Environment's options
      #
      # @since 0.1.0
      # @see Lotus::Environment#initialize
      def initialize(options)
        @environment = Lotus::Environment.new(options)
        @environment.require_application_environment
      end

      # Display to STDOUT application routes
      #
      # @since 0.1.0
      def start
        puts app.routes.inspector.to_s
      end

      private

      # @since 0.1.0
      # @api private
      def app
        if @environment.container?
          Lotus::Container.new
        else
          Lotus::Application.applications.first.new
        end
      end
    end
  end
end
