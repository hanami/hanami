require 'hanami/logger'

module Hanami
  module Config
    # Logger configuration
    #
    # @since x.x.x
    class Logger
      attr_reader :application_module

      def initialize
        @stream = STDOUT
      end

      # Log stream.
      #
      # <tt>STDOUT</tt> by default.
      #
      # It accepts relative or absolute paths expressed as <tt>String</tt>, or
      # <tt>Pathname</tt>.
      #
      # It can also accept a <tt>IO</tt> or <tt>StringIO</tt> as output stream.
      #
      # @overload stream(value)
      #   Sets the given value
      #   @param value [String,Pathname,IO,StringIO] for log stream option.
      #
      # @overload stream
      #   Gets the value
      #   @return [String,Pathname,IO,StringIO] log stream option's value
      #
      # @since x.x.x
      def stream(value = nil)
        if value.nil?
          @stream
        else
          @stream = value
        end
      end

      # Custom logger engine.
      #
      # This isn't used by default, but allows developers to use their own logger.
      #
      # @overload engine(value)
      #   Sets the given value
      #   @param value [Object] a logger
      #
      # @overload engine
      #   Gets the value
      #   @return [Object] returns the logger
      #
      # @since x.x.x
      def engine(value = nil)
        if value.nil?
          @engine
        else
          @engine = value
        end
      end

      # Logger level
      #
      # Available values are:
      #
      #   * DEBUG
      #   * INFO
      #   * WARN
      #   * ERROR
      #   * FATAL
      #   * UNKNOWN
      #
      # @overload level(value)
      #   Sets the given value
      #   @param value [Integer,String,Symbol] the logger level
      #
      # @overload level
      #   Gets the value
      #   @return [Integer,String,Symbol] returns the level
      #
      # @since x.x.x
      #
      # @example Constant (Integer)
      #   require 'hanami/application'
      #
      #   module Bookshelf
      #     class Application < Hanami::Application
      #       configure do
      #         logger.level Hanami::Logger::DEBUG
      #       end
      #     end
      #   end
      #
      # @example String
      #   require 'hanami/application'
      #
      #   module Bookshelf
      #     class Application < Hanami::Application
      #       configure do
      #         logger.level 'debug'
      #       end
      #     end
      #   end
      #
      # @example Symbol
      #   require 'hanami/application'
      #
      #   module Bookshelf
      #     class Application < Hanami::Application
      #       configure do
      #         logger.level :debug
      #       end
      #     end
      #   end
      def level(value = nil)
        if value.nil?
          @level
        else
          @level = value
        end
      end

      # Application name value.
      #
      # @overload app_name(value)
      #   Sets the given value
      #   @param value [String] for app name option
      #
      # @overload app_name
      #   Gets the value
      #   @return [String] app name option's value
      #
      # @since x.x.x
      # @api private
      def app_name(value = nil)
        if value.nil?
          @app_name
        else
          @app_name = value
        end
      end

      # Returns new Hanami::Logger instance with all options
      #
      # @return [Hanami::Logger,Object] a logger
      #
      # @since x.x.x
      # @api private
      #
      # @see Hanami::Config::Logger#stream
      # @see Hanami::Config::Logger#engine
      def build
        @engine ||
          ::Hanami::Logger.new(@app_name, stream: @stream, level: @level)
      end
    end
  end
end
