require 'hanami/commands/command'

module Hanami
  module Commands
    # Display application/container routes.
    #
    # It is run with:
    #
    #   `bundle exec hanami routes`
    #
    # @since 0.1.0
    # @api private
    class Routes < Command
      requires 'routes'

      # Display to STDOUT application routes
      #
      # @since 0.1.0
      def start
        puts requirements['routes'].inspect
      end
    end
  end
end
