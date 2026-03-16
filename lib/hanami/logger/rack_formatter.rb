# frozen_string_literal: true

require "dry/logger"

module Hanami
  module Logger
    # Rack request log formatter for Dry Logger.
    #
    # Formats rack request log entries with colorized output for HTTP verbs, status codes, and
    # request paths, making it easier to visually scan logs in development.
    #
    # HTTP verbs each have a distinct color. Status codes follow traffic-light coloring (2xx green,
    # 3xx cyan, 4xx yellow, 5xx red), and the request path echoes the status color so both signals
    # reinforce each other at a glance.
    #
    # Colorization is only active when `colorize: true` is set in the logger options (the default
    # in development).
    #
    # @api private
    class RackFormatter < Dry::Logger::Formatters::String
      RACK_TEMPLATE = <<~TEXT
        [%<progname>s] [%<severity>s] [%<time>s] \
        %<verb>s %<status>s %<elapsed>s %<ip>s %<path>s %<length>s %<payload>s
          %<params>s
      TEXT

      VERB_COLORS = {
        "GET" => :green,
        "POST" => :yellow,
        "PUT" => :blue,
        "PATCH" => :blue,
        "DELETE" => :red,
        "HEAD" => :cyan
      }.freeze

      Colors = Dry::Logger::Formatters::Colors
      private_constant :Colors

      def initialize(**options)
        super
        @template = Dry::Logger::Formatters::Template[RACK_TEMPLATE]
      end

      private

      def format_values(entry)
        return super unless colorize?

        status_color = status_color(entry.to_h[:status])

        super.merge(
          verb: Colors.call(VERB_COLORS.fetch(entry.to_h[:verb].to_s.upcase, :gray), entry.to_h[:verb]),
          status: Colors.call(status_color, entry.to_h[:status]),
          path: Colors.call(status_color, entry.to_h[:path])
        )
      end

      def format_params(value)
        value unless value.empty?
      end

      def status_color(status)
        case status.to_i
        when 200..299 then :green
        when 300..399 then :cyan
        when 400..499 then :yellow
        when 500..599 then :red
        else :gray
        end
      end
    end
  end
end
