# frozen_string_literal: true

require "hanami/view"
require "pathname"

module Hanami
  class Application
    class View < Hanami::View
      class << self
        def inherited(subclass)
          super

          if subclass.abstract_view? && !subclass.ancestors.include?(Sliced)
            integrate_view_with Hanami.application
          end

          if !subclass.abstract_view?
            subclass.config.template = template_name(subclass, Hanami.application)
          end
        end

        def abstract_view?
          superclass == View
        end

        def [](slice_name)
          target = integration_target(slice_name)

          klass = Class.new(Sliced) do
            integrate_view_with target
          end

          klass.define_singleton_method :inherited do |subclass|
            super(subclass)

            unless subclass.abstract_view?
              subclass.config.template = template_name(subclass, target)
            end
          end

          klass
        end

        def integrate_view_with(target)
          application = Hanami.application

          config.paths = [Pathname(target.root).join(application.config.views.templates_path).to_s]
          config.layouts_dir = application.config.views.layouts_dir
          config.layout = application.config.views.default_layout
        end

        private

        def integration_target(target)
          if target.is_a?(Symbol)
            Hanami.application.slices[target]
          else
            target
          end
        end

        def template_name(view_class, target)
          target.inflector.underscore(view_class.name)
            .sub(/^#{target.namespace_path}\//, "")
            .sub(/^#{Hanami.application.config.views.base_path}\//, "")
        end
      end

      class Sliced < self
        def self.abstract_view?
          superclass == Sliced
        end
      end
    end
  end
end
