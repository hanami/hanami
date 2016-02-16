require 'hanami/logger'

module Hanami
  module Config
    # Logger configuration
    #
    # @since x.x.x
    class Logger
      attr_reader :application_module

      def initialize
        @log_device = STDOUT
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
          @log_device
        else
          @log_device = value
        end
      end

      # Returns new Hanami::Logger instance with all options
      #
      # @return [Hanami::Logger] the new logger instance
      #
      # @since x.x.x
      # @api private
      def build
        ::Hanami::Logger.new(log_device: @log_device)
      end
    end
  end
end
