# frozen_string_literal: true

require "hanami/view"

module Hanami
  # Application integration extensions to Hanami::View
  # @since 2.0.0
  class View
    class << self
      def [](target)
        build_integrated_class(integration_target(target))
      end

      private

      def integration_target(target)
        if target.is_a?(Symbol)
          Hanami.application.slices[target] or raise "Unknown slice +#{target}+"
        else
          target
        end
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def build_integrated_class(target)
        application = Hanami.application

        Class.new(View) do
          config.paths = [target.root.join(application.config.views.templates_path).to_s]
          config.layouts_dir = application.config.views.layouts_dir
          config.layout = application.config.views.default_layout

          define_singleton_method :inherited do |subclass|
            super(subclass)

            unless subclass.superclass == View
              # Do not set template name for abstract "base" view classes
              subclass.config.template = template_name(subclass, target)
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def template_name(view_class, target)
        target
          .inflector
          .underscore(view_class.name)
          .sub(/^#{target.namespace_path}\//, "")
          .sub(/^#{Hanami.application.config.views.base_path}\//, "")
      end
    end
  end
end
