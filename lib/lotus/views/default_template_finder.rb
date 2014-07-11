module Lotus
  module Views
    class DefaultTemplateFinder < Lotus::View::Rendering::TemplateFinder
      def initialize(root, template, format)
        @root = root
        @options = {template: template, format: format}
      end

      private

      def root
        @root
      end
    end
  end
end
