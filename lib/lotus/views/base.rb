module Lotus
  module Views
    # The base view that is rendered for non successful responses (200 and 201)
    #
    # @since 0.1.0
    # @api private
    class Base
      def self.customized_templates_exist?
        Lotus::View::Rendering::TemplatesFinder.new(self).find.any?
      end

      def self.lib_root
        Pathname.new(File.dirname(__FILE__)).join('../templates').realpath
      end

      def title
        response[2].first
      end
    end
  end
end
