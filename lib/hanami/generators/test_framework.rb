require 'hanami/hanamirc'
module Hanami
  # @api private
  module Generators
    # @api private
    class TestFramework
      # @api private
      RSPEC = 'rspec'.freeze
      # @api private
      MINITEST = 'minitest'.freeze
      # @api private
      VALID_FRAMEWORKS = [MINITEST, RSPEC].freeze

      # @api private
      attr_reader :framework

      # @api private
      def initialize(hanamirc, framework)
        @framework = (framework || hanamirc.options.fetch(:test))
        assert_framework!
      end

      # @api private
      def rspec?
        framework == RSPEC
      end

      # @api private
      def minitest?
        framework == MINITEST
      end

      private

      # @api private
      def assert_framework!
        if !supported_framework?
          warn "`#{framework}' is not a valid test framework. Please use one of: #{valid_test_frameworks.join(', ')}"
          exit(1)
        end
      end

      # @api private
      def valid_test_frameworks
        VALID_FRAMEWORKS.map { |name| "`#{name}'"}
      end

      # @api private
      def supported_framework?
        VALID_FRAMEWORKS.include?(framework)
      end

    end
  end
end
