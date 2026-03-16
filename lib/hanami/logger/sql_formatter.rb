# frozen_string_literal: true

require "dry/logger"

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
    # Supports colorization via Dry Logger's template color tags. When `colorize: true` is set in
    # the logger options (the default in development), the "SQL" label is colorized, and severity
    # is colorized per-level by the parent formatter (e.g. INFO => magenta, ERROR => red).
    #
    # When colorization is enabled and the "rouge" gem is available, SQL queries are syntax
    # highlighted using Rouge's SQL lexer. This is a soft dependency; if Rouge is not installed,
    # queries output as plain, unhighlighted text.
    #
    # The Rouge theme defaults to Gruvbox and can be customized by setting the `HANAMI_SQL_THEME`
    # environment variable to any Rouge theme name (e.g. "github.dark", "monokai", "gruvbox.light").
    # See `Rouge::Theme.registry` for available themes.
    #
    # @see Hanami::Logger::SQLLogger
    #
    # @api private
    class SQLFormatter < Dry::Logger::Formatters::String
      SQL_TEMPLATE = <<~TEXT
        [%<progname>s] [%<severity>s] [%<time>s] SQL %<db>s %<elapsed>s%<elapsed_unit>s %<query>s
      TEXT

      SQL_TEMPLATE_COLORIZED = <<~TEXT
        [%<progname>s] [%<severity>s] [%<time>s] <blue>SQL</blue> %<db>s %<elapsed>s%<elapsed_unit>s %<query>s
      TEXT

      def initialize(**options)
        super
        @template = Dry::Logger::Formatters::Template[
          colorize? ? SQL_TEMPLATE_COLORIZED : SQL_TEMPLATE
        ]
        @sql_colorizer = build_sql_colorizer if colorize?
      end

      private

      def format_query(value)
        if @sql_colorizer
          @sql_colorizer.call(value)
        else
          value
        end
      end

      def build_sql_colorizer
        begin
          require "rouge"
        rescue LoadError
          return nil
        end

        theme_name = ENV.fetch("HANAMI_SQL_THEME", "gruvbox")
        theme_class = Rouge::Theme.find(theme_name) || Rouge::Themes::Gruvbox
        formatter = Rouge::Formatters::Terminal256.new(theme_class.new)

        lexer = Rouge::Lexers::SQL.new

        ->(sql) { formatter.format(lexer.lex(sql)) }
      end
    end
  end
end
