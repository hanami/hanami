require 'lotus/views/default_template_finder'

module Lotus
  module Views
    # The default view that is rendered for non successful responses (200 and 201)
    #
    # @since 0.1.0
    # @api private
    class Default
      include Lotus::View
      configuration.reset!

      layout nil
      root Pathname.new(File.dirname(__FILE__)).join('../templates').realpath
      template 'default'

      def title
        response[2].first
      end

      def self.render(root, context)
        format = context[:format]
        template_name = context[:response][0].to_s

        if template = DefaultTemplateFinder.new(root, template_name, format).find
          new(template, context).render
        else
          super(context)
        end
      end
    end
  end
end
