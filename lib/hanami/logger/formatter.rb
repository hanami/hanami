# frozen_string_literal: true

require "set"
require "json"
require "logger"
require "hanami/cyg_utils/json"
require "hanami/cyg_utils/class_attribute"
require "hanami/cyg_utils/query_string"

module Hanami
  class Logger < ::Logger
    # Hanami::Logger default formatter.
    # This formatter returns string in key=value format.
    #
    # @since 0.5.0
    # @api private
    #
    # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
    class Formatter < ::Logger::Formatter
      require "hanami/logger/filter"
      require "hanami/logger/colorizer"

      # @since 0.8.0
      # @api private
      SEPARATOR = " "

      # @since 0.8.0
      # @api private
      NEW_LINE = $/

      # @since 1.0.0
      # @api private
      RESERVED_KEYS = %i[app severity time].freeze

      include CygUtils::ClassAttribute

      class_attribute :subclasses
      self.subclasses = Set.new

      def self.fabricate(formatter, application_name, filters, colorizer)
        fabricated_formatter = _formatter_instance(formatter)

        fabricated_formatter.application_name = application_name
        fabricated_formatter.filter           = Filter.new(filters)
        fabricated_formatter.colorizer        = colorizer

        fabricated_formatter
      end

      # @api private
      def self.inherited(subclass)
        super
        subclasses << subclass
      end

      # @api private
      def self.eligible?(name)
        name == :default
      end

      # @api private
      # @since 1.1.0
      def self._formatter_instance(formatter)
        case formatter
        when Symbol
          (subclasses.find { |s| s.eligible?(formatter) } || self).new
        when nil
          new
        else
          formatter
        end
      end
      private_class_method :_formatter_instance

      # @since 0.5.0
      # @api private
      attr_writer :application_name

      # @since 1.0.0
      # @api private
      attr_reader :application_name

      # @since 1.2.0
      # @api private
      attr_writer :filter

      # @since 1.2.0
      # @api private
      attr_writer :colorizer

      # @since 0.5.0
      # @api private
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
      def call(severity, time, progname, msg)
        colorized = @colorizer.call(application_name, severity, time, progname)
        colorized.merge!(_message_hash(msg))

        _format(colorized)
      end

      private

      # @since 0.8.0
      # @api private
      def _message_hash(message)
        case message
        when Hash
          @filter.call(message)
        when Exception
          Hash[
            message: message.message,
            backtrace: message.backtrace || [],
            error: message.class
          ]
        else
          Hash[message: message]
        end
      end

      # @since 0.8.0
      # @api private
      def _format(hash)
        "#{_line_front_matter(hash.delete(:app), hash.delete(:severity), hash.delete(:time))}#{SEPARATOR}#{_format_message(hash)}" # rubocop:disable Layout/LineLength
      end

      # @since 1.2.0
      # @api private
      def _line_front_matter(*args)
        args.map { |string| "[#{string}]" }.join(SEPARATOR)
      end

      # @since 1.2.0
      # @api private
      def _format_message(hash)
        if hash.key?(:error)
          _format_error(hash)
        elsif hash.key?(:params)
          "#{hash.values.join(SEPARATOR)}#{NEW_LINE}"
        else
          "#{CygUtils::QueryString.call(hash[:message] || hash)}#{NEW_LINE}"
        end
      end

      # @since 1.2.0
      # @api private
      def _format_error(hash)
        result = [hash[:error], hash[:message]].compact.join(": ").concat(NEW_LINE)
        hash[:backtrace].each do |line|
          result << "from #{line}#{NEW_LINE}"
        end

        result
      end
    end

    # Hanami::Logger JSON formatter.
    # This formatter returns string in JSON format.
    #
    # @since 0.5.0
    # @api private
    class JSONFormatter < Formatter
      # @api private
      def self.eligible?(name)
        name == :json
      end

      # @api private
      def colorizer=(*)
        @colorizer = NullColorizer.new
      end

      private

      # @since 0.8.0
      # @api private
      def _format(hash)
        hash[:time] = hash[:time].utc.iso8601
        Hanami::CygUtils::Json.generate(hash) + NEW_LINE
      end
    end
  end
end
