require 'logger'
require 'lotus/utils/string'

module Lotus
  # Lotus logger
  #
  # Implement with the same interface of Ruby std lib `Logger`.
  # It uses `STDOUT` as output device.
  #
  #
  #
  # When a Lotus application is initialized, it creates a logger for that specific application.
  # For instance for a `Bookshelf::Application` a `Bookshelf::Logger` will be available.
  #
  # This is useful for auto-tagging the output. Eg (`[Booshelf]`).
  #
  # When used stand alone (eg. `Lotus::Logger.info`), it tags lines with `[Shared]`.
  #
  #
  #
  # The available severity levels are the same of `Logger`:
  #
  #   * debug
  #   * error
  #   * fatal
  #   * info
  #   * unknown
  #   * warn
  #
  # Those levels are available both as class and instance methods.
  #
  # @since 0.2.1
  #
  # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html
  # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Severity.html
  #
  # @example Basic usage
  #   require 'lotus'
  #
  #   module Bookshelf
  #     class Application < Lotus::Application
  #     end
  #   end
  #
  #   # Initialize the application with the following code:
  #   Bookshelf::Application.load!
  #   # or
  #   Bookshelf::Application.new
  #
  #   Bookshelf::Logger.info('Hello')
  #   # => I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [Bookshelf] : Hello
  #
  #   Bookshelf::Logger.new.info('Hello')
  #   # => I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [Bookshelf] : Hello
  #
  # @example Standalone usage
  #   require 'lotus'
  #
  #   Lotus::Logger.info('Hello')
  #   # => I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [Lotus] : Hello
  #
  #   Lotus::Logger.new.info('Hello')
  #   # => I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [Lotus] : Hello
  #
  # @example Custom tagging
  #   require 'lotus'
  #
  #   Lotus::Logger.new('FOO').info('Hello')
  #   # => I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [FOO] : Hello
  class Logger < ::Logger
    # Lotus::Logger default formatter
    #
    # @since 0.2.1
    # @api private
    #
    # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
    class Formatter < ::Logger::Formatter
      # @since 0.2.1
      # @api private
      attr_writer :application_name

      # @since 0.2.1
      # @api private
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
      def call(severity, time, progname, msg)
        progname = "[#{@application_name}] #{progname}"
        super(severity, time.utc, progname, msg)
      end
    end

    # Default application name.
    # This is used as a fallback for tagging purposes.
    #
    # @since 0.2.1
    # @api private
    DEFAULT_APPLICATION_NAME = 'Lotus'.freeze

    # @since 0.2.1
    # @api private
    attr_writer :application_name

    # Initialize a logger
    #
    # @param application_name [String] an optional application name used for
    #   tagging purposes
    #
    # @since 0.2.1
    def initialize(application_name = nil)
      super(STDOUT)

      @application_name = application_name
      @formatter        = Lotus::Logger::Formatter.new.tap { |f| f.application_name = self.application_name }
    end

    # Returns the current application name, this is used for tagging purposes
    #
    # @return [String] the application name
    #
    # @since 0.2.1
    def application_name
      @application_name || _application_name_from_namespace || _default_application_name
    end

    private
    # @since 0.2.1
    # @api private
    def _application_name_from_namespace
      class_name = self.class.name
      namespace  = Utils::String.new(class_name).namespace

      class_name != namespace and return namespace
    end

    # @since 0.2.1
    # @api private
    def _default_application_name
      DEFAULT_APPLICATION_NAME
    end
  end
end
