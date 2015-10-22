module Lotus
  module Generators
    class TestFramework
      RSPEC = 'rspec'.freeze
      MINITEST = 'minitest'.freeze
      VALID_FRAMEWORKS = [RSPEC, MINITEST].freeze
      DEFAULT_FRAMEWORK = Lotus::DEFAULT_TEST_FRAMEWORK

      attr_reader :framework

      def initialize(framework)
        @framework = (framework || DEFAULT_FRAMEWORK)
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
          raise ArgumentError.new("Unknown test framework '#{ framework }'. Please use one of #{ valid_test_frameworks.join(', ') }")
        end
      end

      def valid_test_frameworks
        VALID_FRAMEWORKS.map { |name| "'#{ name }'"}
      end

      def supported_framework?
        VALID_FRAMEWORKS.include?(framework)
      end

    end
  end
end
