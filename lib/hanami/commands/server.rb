require 'hanami/commands/command'

module Hanami
  module Commands
    # Server command (`hanami server`)
    #
    # @since 0.1.0
    # @api private
    class Server < Command
      requires 'code_reloading'

      # Message text when Shotgun enabled but interpreter does not support `fork`
      #
      # @since 0.8.0
      # @api private
      WARNING_MESSAGE = 'Your platform doesn\'t support code reloading.'.freeze

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
