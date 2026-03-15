# frozen_string_literal: true

module Hanami
  module Logger
    # SQL query logger that integrates with the Hanami logger using structured, tagged logging.
    #
    # Subscribes to `:sql` notification events (emitted by ROM via the Hanami app's
    # `"notifications"` component) and logs each query as a structured payload. The log entries are
    # tagged as `:sql`, which allows Dry Logger backends to route them to a dedicated formatter (see
    # {SQLFormatter}), in the same way that rack log entries are routed using the `:rack` tag.
    #
    # @see SQLFormatter
    # @see Hanami::Providers::DBLogging
    #
    # @api private
    class SQLLogger
      attr_reader :logger

      # @param logger [#tagged, #info] a Hanami-compatible logger (typically a
      #   Dry::Logger::Dispatcher or a {Hanami::UniversalLogger}-wrapped logger)
      def initialize(logger)
        @logger = logger
      end

      # Subscribes to `:sql` notification events.
      #
      # @param notifications [Dry::Monitor::Notifications] the notifications bus
      # @return [void]
      def subscribe(notifications)
        notifications.subscribe(:sql) { |params| log_query(**params) }
      end

      # Log a SQL query with structured data.
      #
      # @param time [Numeric] elapsed time in milliseconds
      # @param name [Symbol] database adapter name (e.g. `:sqlite`, `:postgres`)
      # @param query [String] the SQL query string
      def log_query(time:, name:, query:)
        logger.tagged(:sql) do
          logger.info do
            {query:, db: name, elapsed: time.round(3), elapsed_unit: "ms"}
          end
        end
      end
    end
  end
end
