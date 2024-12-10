# frozen_string_literal: true

require "hanami/utils"

module Hanami
  module CygUtils
    # Prints a deprecation warning when initialized
    #
    # @since 0.3.1
    class Deprecation
      # Initialize a deprecation message and prints it to standard error.
      #
      # @param message [#to_s] a deprecation message
      #
      # @since 0.3.1
      #
      # @example Direct usage
      #   require 'hanami/cyg_utils/deprecation'
      #
      #   class Engine
      #     def old_method
      #       Hanami::CygUtils::Deprecation.new('old_method is deprecated, please use new_method')
      #       new_method
      #     end
      #
      #     def new_method
      #       puts 'started'
      #     end
      #   end
      #
      #   Engine.new.old_method
      #     # => old_method is deprecated, please use new_method - called from: test.rb:14:in `<main>'.
      #     # => started
      #
      # @example Indirect usage
      #   require 'hanami/cyg_utils/deprecation'
      #
      #   class Engine
      #     def old_method
      #       Hanami::CygUtils::Deprecation.new('old_method is deprecated, please use new_method')
      #       new_method
      #     end
      #
      #     def new_method
      #       puts 'started'
      #     end
      #   end
      #
      #   class Car
      #     def initialize
      #       @engine = Engine.new
      #     end
      #
      #     def start
      #       @engine.old_method
      #     end
      #   end
      #
      #   Car.new.start
      #     # => old_method is deprecated, please use new_method - called from: test.rb:20:in `start'.
      #     # => started
      def initialize(message)
        ::Kernel.warn("#{message} - called from: #{caller[caller_index]}.")
      end

      private

      # @api private
      def caller_index
        Utils.jruby? || Utils.rubinius? ? 1 : 2
      end
    end
  end
end
