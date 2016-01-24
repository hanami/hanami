require 'hanami/hanamirc'

module Hanami
  module Generators
    class ConsoleEngine
      SUPPORTED_ENGINES = ['pry', 'irb', 'ripl'].freeze

      DEFAULT_ENGINE = 'irb'.freeze

      attr_reader :engine

      def initialize(hanamirc, engine)
        @engine = (engine || hanamirc.options.fetch(:console))
        assert_engine!
      end

      def irb?
        engine == 'irb'
      end

      def pry?
        engine == 'pry'
      end

      def ripl?
        engine == 'ripl'
      end

      private

      def assert_engine!
        if !supported_engine?
          raise ArgumentError.new("Unknown console engine '#{engine}'. Please use one of #{ valid_console_engines.join(', ')}")
        end
      end

      def valid_console_engines
        SUPPORTED_ENGINES.map { |name| "'#{ name }'"}
      end

      def supported_engine?
        SUPPORTED_ENGINES.include?(engine)
      end

    end
  end
end
