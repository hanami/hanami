module Lotus
  module Views
    class DefaultTemplateFinder < View::Rendering::TemplateFinder
      # Template Finder
      #
      # @since 0.2.0
      # @api private
      def initialize(root, template_name, format)
         @root    = root
         @options = { template: template_name, format: format }
      end

      private
      def root
        @root
      end
    end
  end
end
