module Lotus
  module Generators
    class TemplateEngine

      SUPPORTED_ENGINES = %w(erb slim haml).freeze

      attr_reader :engine

      def initialize(engine)
        @engine = engine || Lotus::DEFAULT_TEMPLATE_ENGINE
        SUPPORTED_ENGINES.include?(@engine.to_s) or fail "\"#{ @engine }\" is not a valid template engine"
      end
    end
  end
end
