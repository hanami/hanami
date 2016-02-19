require 'hanami/logger'

module Hanami
  module Config
    # Logger configuration
    #
    # @since x.x.x
    class Logger
      attr_reader :application_module

      def initialize
        @device = STDOUT
      end

      # Log device option value. STDOUT by default
      #
      # @overload stream(value)
      #   Sets the given value
      #   @param value [String] for log device option.
      #
      # @overload stream
      #   Gets the value
      #   @return [String] log device option's value
      #
      # @since x.x.x
      # @api private
      def stream(value = nil)
        if value.nil?
          @device
        else
          @device = value
        end
      end

      # Custom log instance value. `nil` by default
      #
      # @overload stream(value)
      #   Sets the given value
      #   @param value [String] for custom log instance value.
      #
      # @overload stream
      #   Gets the value
      #   @return [String] custom log instance value
      #
      # @since x.x.x
      # @api private
      def custom_logger(value = nil)
        if value.nil?
          @custom_logger
        else
          @custom_logger = value
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
      # @return [Hanami::Logger] the new logger instance
      #
      # @since x.x.x
      # @api private
      def build
        @custom_logger ||
          ::Hanami::Logger.new(@app_name, device: @device)
      end
    end
  end
end
