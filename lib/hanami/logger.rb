# frozen_string_literal: true

require "logger"
require "hanami/cyg_utils/string"
require "hanami/cyg_utils/files"

module Hanami
  # Hanami logger
  #
  # Implementation with the same interface of Ruby std lib `Logger`.
  # It uses `STDOUT`, `STDERR`, file name or open file as output stream.
  #
  #
  # When a Hanami application is initialized, it creates a logger for that specific application.
  # For instance for a `Bookshelf::Application` a `Bookshelf::Logger` will be available.
  #
  # This is useful for auto-tagging the output. Eg (`app=Booshelf`).
  #
  # When used standalone (eg. `Hanami::Logger.info`), it tags lines with `app=Shared`.
  #
  #
  # The available severity levels are the same of `Logger`:
  #
  #   * DEBUG
  #   * INFO
  #   * WARN
  #   * ERROR
  #   * FATAL
  #   * UNKNOWN
  #
  # Those levels are available both as class and instance methods.
  #
  # Also Hanami::Logger supports different formatters. Now available only two:
  #
  #   * Formatter (default)
  #   * JSONFormatter
  #
  # And if you want to use custom formatter you need create new class inherited from
  # `Formatter` class and define `_format` private method like this:
  #
  #     class CustomFormatter < Formatter
  #       private
  #       def _format(hash)
  #         # ...
  #       end
  #     end
  #
  # @since 0.5.0
  #
  # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html
  # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Severity.html
  #
  # @example Basic usage
  #   require 'hanami'
  #
  #   module Bookshelf
  #     class Application < Hanami::Application
  #     end
  #   end
  #
  #   # Initialize the application with the following code:
  #   Bookshelf::Application.load!
  #   # or
  #   Bookshelf::Application.new
  #
  #   Bookshelf::Logger.new.info('Hello')
  #   # => app=Bookshelf severity=INFO time=1988-09-01 00:00:00 UTC message=Hello
  #
  # @example Standalone usage
  #   require 'hanami/logger'
  #
  #   Hanami::Logger.new.info('Hello')
  #   # => app=Hanami severity=INFO time=2016-05-27 10:14:42 UTC message=Hello
  #
  # @example Custom tagging
  #   require 'hanami/logger'
  #
  #   Hanami::Logger.new('FOO').info('Hello')
  #   # => app=FOO severity=INFO time=2016-05-27 10:14:42 UTC message=Hello
  #
  # @example Write to file
  #   require 'hanami/logger'
  #
  #   Hanami::Logger.new(stream: 'logfile.log').info('Hello')
  #   # in logfile.log
  #   # => app=FOO severity=INFO time=2016-05-27 10:14:42 UTC message=Hello
  #
  # @example Use JSON formatter
  #   require 'hanami/logger'
  #
  #   Hanami::Logger.new(formatter: Hanami::Logger::JSONFormatter).info('Hello')
  #   # => "{\"app\":\"Hanami\",\"severity\":\"INFO\",\"time\":\"1988-09-01 00:00:00 UTC\",\"message\":\"Hello\"}"
  #
  # @example Disable colorization
  #   require 'hanami/logger'
  #
  #   Hanami::Logger.new(colorizer: false)
  #
  # @example Use custom colors
  #   require 'hanami/logger'
  #
  #   Hanami::Logger.new(colorizer: Hanami::Logger::Colorizer.new(colors: { app: :red }))
  #
  # @example Use custom colorizer
  #   require "hanami/logger"
  #   require "paint" # gem install paint
  #
  #   class LogColorizer < Hanami::Logger::Colorizer
  #     def initialize(colors: { app: [:red, :bright], severity: [:red, :blue], datetime: [:italic, :yellow] })
  #       super
  #     end
  #
  #     private
  #
  #     def colorize(message, color:)
  #       Paint[message, *color]
  #     end
  #   end
  #
  #   Hanami::Logger.new(colorizer: LogColorizer.new)
  class Logger < ::Logger
    require "hanami/logger/formatter"
    require "hanami/logger/colorizer"

    # Default application name.
    # This is used as a fallback for tagging purposes.
    #
    # @since 0.5.0
    # @api private
    DEFAULT_APPLICATION_NAME = "hanami"

    # @since 0.8.0
    # @api private
    LEVELS = ::Hash[
      "debug" => DEBUG,
      "info" => INFO,
      "warn" => WARN,
      "error" => ERROR,
      "fatal" => FATAL,
      "unknown" => UNKNOWN
    ].freeze

    # @since 1.2.0
    # @api private
    def self.level(level)
      case level
      when DEBUG..UNKNOWN
        level
      else
        LEVELS.fetch(level.to_s.downcase, DEBUG)
      end
    end

    # @since 0.5.0
    # @api private
    attr_writer :application_name

    # Initialize a logger
    #
    # @param application_name [String] an optional application name used for
    #   tagging purposes
    #
    # @param args [Array<Object>] an optional set of arguments to honor Ruby's
    #   `Logger#initialize` arguments. See Ruby documentation for details.
    #
    # @param stream [String, IO, StringIO, Pathname] an optional log stream.
    #   This is a filename (`String`) or `IO` object (typically `$stdout`,
    #   `$stderr`, or an open file). It defaults to `$stderr`.
    #
    # @param level [Integer,String] logging level. It can be expressed as an
    #   integer, according to Ruby's `Logger` from standard library or as a
    #   string with the name of the level
    #
    # @param formatter [Symbol,#_format] a formatter - We support `:json` as
    #   JSON formatter or an object that respond to `#_format(data)`
    #
    # @since 0.5.0
    #
    # @see https://ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html#class-Logger-label-How+to+create+a+logger
    #
    # @example Basic usage
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new
    #   logger.info "Hello World"
    #
    #   # => [Hanami] [DEBUG] [2017-03-30 15:41:01 +0200] Hello World
    #
    # @example Custom application name
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new('bookshelf')
    #   logger.info "Hello World"
    #
    #   # => [bookshelf] [DEBUG] [2017-03-30 15:44:23 +0200] Hello World
    #
    # @example Logger level (Integer)
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new(level: 2) # WARN
    #   logger.info "Hello World"
    #   # => true
    #
    #   logger.info "Hello World"
    #   # => true
    #
    #   logger.warn "Hello World"
    #   # => [Hanami] [WARN] [2017-03-30 16:00:48 +0200] Hello World
    #
    # @example Logger level (Constant)
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new(level: Hanami::Logger::WARN)
    #   logger.info "Hello World"
    #   # => true
    #
    #   logger.info "Hello World"
    #   # => true
    #
    #   logger.warn "Hello World"
    #   # => [Hanami] [WARN] [2017-03-30 16:00:48 +0200] Hello World
    #
    # @example Logger level (String)
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new(level: 'warn')
    #   logger.info "Hello World"
    #   # => true
    #
    #   logger.info "Hello World"
    #   # => true
    #
    #   logger.warn "Hello World"
    #   # => [Hanami] [WARN] [2017-03-30 16:00:48 +0200] Hello World
    #
    # @example Use a file
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new(stream: "development.log")
    #   logger.info "Hello World"
    #
    #   # => true
    #
    #   File.read("development.log")
    #   # =>
    #   #  # Logfile created on 2017-03-30 15:52:48 +0200 by logger.rb/56815
    #   #  [Hanami] [DEBUG] [2017-03-30 15:52:54 +0200] Hello World
    #
    # @example Period rotation
    #   require 'hanami/logger'
    #
    #   # Rotate daily
    #   logger = Hanami::Logger.new('bookshelf', 'daily', stream: 'development.log')
    #
    # @example File size rotation
    #   require 'hanami/logger'
    #
    #   # leave 10 old log files where the size is about 1,024,000 bytes
    #   logger = Hanami::Logger.new('bookshelf', 10, 1024000, stream: 'development.log')
    #
    # @example Use a StringIO
    #   require 'hanami/logger'
    #
    #   stream = StringIO.new
    #   logger = Hanami::Logger.new(stream: stream)
    #   logger.info "Hello World"
    #
    #   # => true
    #
    #   stream.rewind
    #   stream.read
    #
    #   # => "[Hanami] [DEBUG] [2017-03-30 15:55:22 +0200] Hello World\n"
    #
    # @example JSON formatter
    #   require 'hanami/logger'
    #
    #   logger = Hanami::Logger.new(formatter: :json)
    #   logger.info "Hello World"
    #
    #   # => {"app":"Hanami","severity":"DEBUG","time":"2017-03-30T13:57:59Z","message":"Hello World"}
    # rubocop:disable Lint/SuppressedException
    # rubocop:disable Metrics/ParameterLists
    def initialize(application_name = nil, *args, stream: $stdout, level: DEBUG, formatter: nil, filter: [], colorizer: nil, **kwargs) # rubocop:disable Layout/LineLength
      begin
        CygUtils::Files.mkdir_p(stream)
      rescue TypeError
      end

      super(stream, *args, **kwargs)

      @level            = _level(level)
      @stream           = stream
      @application_name = application_name
      @formatter        = Formatter.fabricate(formatter, self.application_name, filter, lookup_colorizer(colorizer))
    end

    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Lint/SuppressedException

    # Returns the current application name, this is used for tagging purposes
    #
    # @return [String] the application name
    #
    # @since 0.5.0
    def application_name
      @application_name || _application_name_from_namespace || _default_application_name
    end

    # @since 0.8.0
    # @api private
    def level=(value)
      super _level(value)
    end

    # Closes the logging stream if this stream isn't an STDOUT
    #
    # @since 0.8.0
    def close
      super unless [STDOUT, $stdout].include?(@stream)
    end

    private

    # @since 0.5.0
    # @api private
    def _application_name_from_namespace
      class_name = self.class.name
      namespace  = CygUtils::String.namespace(class_name)

      class_name != namespace and return namespace
    end

    # @since 0.5.0
    # @api private
    def _default_application_name
      DEFAULT_APPLICATION_NAME
    end

    # @since 0.8.0
    # @api private
    def _level(level)
      self.class.level(level)
    end

    # @since 1.2.0
    # @api private
    def lookup_colorizer(colorizer)
      return NullColorizer.new if colorizer == false

      colorizer || (tty? ? Colorizer : NullColorizer).new
    end

    # @since 1.2.0
    # @api private
    def tty?
      @logdev.dev.tty?
    end
  end
end
