# frozen_string_literal: true

module Hanami
  module CygUtils
    # Shell helper for colorizing STDOUT
    #
    # It doesn't check if you're writing to a file or anything, so you have to
    # check that yourself before using this module.
    #
    # @since 1.2.0
    module ShellColor
      # Unknown color code error
      #
      # @since 1.2.0
      class UnknownColorCodeError < ::StandardError
        def initialize(code)
          super("unknown color code: `#{code.inspect}'")
        end
      end

      # Escapes codes for terminals to output strings in colors
      #
      # @since 1.2.0
      # @api private
      COLORS = ::Hash[
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        gray: 37,
      ].freeze

      # Colorizes output
      # 8 colors available: black, red, green, yellow, blue, magenta, cyan, and gray
      #
      # @param input [#to_s] the string to colorize
      # @param color [Symbol] the color
      #
      # @raise [Hanami::CygUtils::ShellColor::UnknownColorError] if the color code is
      #   unknown
      #
      # @return [String] the colorized string
      #
      # @since 1.2.0
      def self.call(input, color:)
        "\e[#{color_code(color)}m#{input}\e[0m"
      end

      # Helper method to translate between color names and terminal escape codes
      #
      # @api private
      # @since 1.2.0
      #
      # @raise [Hanami::CygUtils::ShellColor::UnknownColorError] if the color code is
      #   unknown
      def self.color_code(code)
        COLORS.fetch(code) { raise UnknownColorCodeError.new(code) }
      end
    end
  end
end
