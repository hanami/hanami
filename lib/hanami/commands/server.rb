require 'hanami/commands/command'

module Hanami
  # @api private
  module Commands
    # Server command (`hanami server`)
    #
    # @since 0.1.0
    # @api private
    class Server < Command
      requires 'code_reloading'

      # @api private
      def initialize(options)
        super(options)

        require 'hanami/server'
        @server = Hanami::Server.new
      end

      # @api private
      def start
        server.start
      end

      protected

      # @api private
      attr_reader :server
    end
  end
end
