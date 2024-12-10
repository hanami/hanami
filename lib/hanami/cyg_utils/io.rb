# frozen_string_literal: true

module Hanami
  module CygUtils
    # IO utils
    #
    # @since 0.1.0
    class IO
      # Decreases the level of verbosity, during the execution of the given block.
      #
      # Revised version of ActiveSupport's `Kernel.with_warnings` implementation
      # @see https://github.com/rails/rails/blob/v4.1.2/activesupport/lib/active_support/core_ext/kernel/reporting.rb#L25
      #
      # @yield the block of code that generates warnings.
      #
      # @return [void]
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/io'
      #
      #   class Test
      #     TEST_VALUE = 'initial'
      #   end
      #
      #   Hanami::CygUtils::IO.silence_warnings do
      #     Test::TEST_VALUE = 'redefined'
      #   end
      def self.silence_warnings
        old_verbose = $VERBOSE
        $VERBOSE    = nil
        yield
      ensure
        $VERBOSE = old_verbose
      end
    end
  end
end
