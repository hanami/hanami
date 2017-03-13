module Hanami
  # @api private
  module Generators
    # @api private
    class TemplateEngine
      class UnsupportedTemplateEngine < ::StandardError
      end

      # @api private
      SUPPORTED_ENGINES = %w(erb haml slim).freeze
      # @api private
      DEFAULT_ENGINE = 'erb'.freeze

      # @api private
      attr_reader :name

      # @api private
      def initialize(hanamirc, engine)
        @name = (engine || hanamirc.options.fetch(:template))
        assert_engine!
      end

      private

      # @api private
      def assert_engine!
        if !supported_engine?
          warn "`#{name}' is not a valid template engine. Please use one of: #{valid_template_engines.join(', ')}"
          exit(1)
        end
      end

      # @api private
      def valid_template_engines
        SUPPORTED_ENGINES.map { |name| "`#{name}'"}
      end

      # @api private
      def supported_engine?
        SUPPORTED_ENGINES.include?(@name.to_s)
      end
    end
  end
end
