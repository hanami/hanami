module Hanami
  module Generators
    class TemplateEngine
      class UnsupportedTemplateEngine < ::StandardError
      end

      SUPPORTED_ENGINES = %w(erb slim haml).freeze
      DEFAULT_ENGINE = 'erb'.freeze

      attr_reader :name

      def initialize(hanamirc, engine)
        @name = (engine || hanamirc.options.fetch(:template))
        assert_engine!
      end

      private

      def assert_engine!
        unless supported_engine?
          raise UnsupportedTemplateEngine, "\"#{ @name }\" is not a valid template engine"
        end
      end

      def supported_engine?
        SUPPORTED_ENGINES.include?(@name.to_s)
      end
    end
  end
end
