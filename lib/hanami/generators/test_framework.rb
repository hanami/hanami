require 'hanami/hanamirc'
module Hanami
  module Generators
    class TestFramework
      RSPEC = 'rspec'.freeze
      MINITEST = 'minitest'.freeze
      VALID_FRAMEWORKS = [MINITEST, RSPEC].freeze

      attr_reader :framework

      def initialize(hanamirc, framework)
        @framework = (framework || hanamirc.options.fetch(:test))
        assert_framework!
      end

      def rspec?
        framework == RSPEC
      end

      def minitest?
        framework == MINITEST
      end

      private

      def assert_framework!
        if !supported_framework?
          warn "`#{framework}' is not a valid test framework. Please use one of: #{valid_test_frameworks.join(', ')}"
          exit(1)
        end
      end

      def valid_test_frameworks
        VALID_FRAMEWORKS.map { |name| "`#{name}'"}
      end

      def supported_framework?
        VALID_FRAMEWORKS.include?(framework)
      end

    end
  end
end
