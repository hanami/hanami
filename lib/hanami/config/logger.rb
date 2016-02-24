require 'hanami/logger'

module Hanami
  module Config
    # Logger configuration
    #
    # @since x.x.x
    class Logger
      attr_reader :application_module

      # @since x.x.x
      # @api private
      LEVEL_HASH = {
        warn:    Hanami::Logger::WARN,
        info:    Hanami::Logger::INFO,
        fatal:   Hanami::Logger::FATAL,
        error:   Hanami::Logger::ERROR,
        debug:   Hanami::Logger::DEBUG,
        unknown: Hanami::Logger::UNKNOWN
      }

      def initialize
        @device = STDOUT
        @level  = Hanami::Logger::DEBUG
      end

      # Log device.
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
      #   @param value [String,Pathname,IO,StringIO] for log device option.
      #
      # @overload stream
      #   Gets the value
      #   @return [String,Pathname,IO,StringIO] log device option's value
      #
      # @since x.x.x
      def stream(value = nil)
        if value.nil?
          @device
        else
          @device = value
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
      # @overload level(value)
      #   Sets the given value
      #   @param value [Object] a level
      #
      # @overload level
      #   Gets the value
      #   @return [Object] returns the level
      #
      # @since x.x.x
      def level(value = nil)
        if value.nil?
          @level
        else
          @level = detect_level(value)
        end
      end

      # Application name value.
      #
      # @overload stream(value)
      #   Sets the given value
      #   @param value [String] for app name option
      #
      # @overload stream
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
          ::Hanami::Logger.new(@app_name, device: @device)
      end

    private

      def detect_level(level)
        level.is_a?(Integer) ? level : LEVEL_HASH[level.to_sym.downcase]
      end
    end
  end
end
