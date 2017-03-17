module Hanami
  module Views
    # @api private
    class DefaultTemplateFinder < View::Rendering::TemplateFinder
      # Template Finder
      #
      # @since 0.2.0
      # @api private
      def initialize(view, root, template_name, format)
        @view    = view
        @root    = root
        @options = { template: template_name, format: format }
      end

      private
      # @api private
      def root
        @root
      end
    end
  end
end
