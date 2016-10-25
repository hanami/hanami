module Hanami
  module Generators
    class TemplateEngine
      class UnsupportedTemplateEngine < ::StandardError
      end

      SUPPORTED_ENGINES = %w(erb haml slim).freeze
      DEFAULT_ENGINE = 'erb'.freeze

      attr_reader :name

      def initialize(hanamirc, engine)
        @name = (engine || hanamirc.options.fetch(:template))
        assert_engine!
      end

      private

      def assert_engine!
        if !supported_engine?
          warn "`#{name}' is not a valid template engine. Please use one of: #{valid_template_engines.join(', ')}"
          exit(1)
        end
      end

      def valid_template_engines
        SUPPORTED_ENGINES.map { |name| "`#{name}'"}
      end

      def supported_engine?
        SUPPORTED_ENGINES.include?(@name.to_s)
      end
    end
  end
end
