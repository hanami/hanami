# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    # Provider source to register logger component in Hanami slices.
    #
    # @see Hanami::Config#logger
    #
    # @api private
    # @since 2.0.0
    class Logger < Dry::System::Provider::Source
      # @api private
      def start
        register :logger, Hanami.app.config.logger_instance
      end
    end
  end
end
