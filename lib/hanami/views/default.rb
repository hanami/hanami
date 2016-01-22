require 'hanami/views/default_template_finder'

module Hanami
  module Views
    # The default view that is rendered for non successful responses (200 and 201)
    #
    # @since 0.1.0
    # @api private
    class Default
      include Hanami::View

      configuration.reset!

      layout nil
      root Pathname.new(File.dirname(__FILE__)).join('../templates').realpath
      template 'default'

      def title
        response[2].first
      end

      def self.render(root, template_name, context)
        format   = context[:format]
        template = DefaultTemplateFinder.new(self, root, template_name, format).find

        if template
          new(template, context).render
        else
          super(context)
        end
      end
    end
  end
end
