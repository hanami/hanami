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
    class Logger < Hanami::Provider::Source
      # @api private
      def start
        register :logger, logger
      end

      # Returns the logger instance that will be registered as the slice's `"logger"` component.
      #
      # This is memoized, so lifecycle callbacks added when extending the provider via
      # {Hanami::Slice::ClassMethods#configure_provider} (such as a `before :start` or `after :start`
      # hook) can access and customize the very same logger that `start` registers — for example, to
      # add a logging backend.
      #
      # @return [Dry::Logger::Dispatcher] the default logger, or the logger instance configured via
      #   {Hanami::Config#logger=}
      #
      # @api public
      # @since 3.0.0
      def logger
        @logger ||= Hanami.app.config.logger_instance
      end
    end

    Dry::System.register_provider_source(
      :logger,
      source: Logger,
      group: :hanami
    )
  end
end
