require 'hanami/commands/command'

module Hanami
  module Commands
    # Server command (`hanami server`)
    #
    # @since 0.1.0
    # @api private
    class Server < Command
      requires 'code_reloading'

      def initialize(options)
        super(options)

        require 'hanami/server'
        @server = Hanami::Server.new
      end

      def start
        server.start
      end

      protected

      attr_reader :server
    end
  end
end
