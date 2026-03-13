# frozen_string_literal: true

require "dry/logger/formatters/string"

module Hanami
  module Logger
    # SQL query log formatter for Dry Logger.
    #
    # Formats SQL query log entries with a template that mirrors the structure of the built-in rack
    # log formatter, providing consistent visual formatting across both HTTP request and database
    # query logs.
    #
    # For example, in development, SQL logs alongside Rack logs:
    #
    #   [my_app] [INFO] [2026-03-04 10:15:32] SQL sqlite 1.234ms SELECT * FROM users
    #   [my_app] [INFO] [2026-03-04 10:15:32] GET 200 1ms 127.0.0.1 /users -
    #
    # In production, the default JSON formatter handles SQL entries automatically via the structured
    # payload.
    #
    # Supports colorization via dry-logger's template color tags. When `colorize: true` is set in
    # the logger options (the default in development), the "SQL" label and severity are colorized.
    #
    # @see Hanami::Logger::SQLLogger
    #
    # @api private
    class SQLFormatter < Dry::Logger::Formatters::String
      SQL_TEMPLATE = <<~TEXT
        [%<progname>s] [%<severity>s] [%<time>s] SQL %<db>s %<elapsed>s%<elapsed_unit>s %<query>s
      TEXT

      SQL_TEMPLATE_COLORIZED = <<~TEXT
        [%<progname>s] [<cyan>%<severity>s</cyan>] [%<time>s] <blue>SQL</blue> %<db>s %<elapsed>s%<elapsed_unit>s %<query>s
      TEXT

      def initialize(**options)
        super
        @template = Dry::Logger::Formatters::Template[
          colorize? ? SQL_TEMPLATE_COLORIZED : SQL_TEMPLATE
        ]
      end
    end
  end
end
