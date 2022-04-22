# frozen_string_literal: true

require "hanami/view"

module Hanami
  class Application
    class View < Hanami::View
      # Provides slice-specific configuration and behavior for any view class defined
      # within a slice's module namespace.
      #
      # @api private
      # @since 2.0.0
      class SliceConfiguredView < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(view_class)
          configure_view(view_class)
          define_inherited
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        # rubocop:disable Metrics/AbcSize
        def configure_view(view_class)
          view_class.settings.each do |setting|
            if slice.application.config.views.respond_to?(:"#{setting}")
              view_class.config.public_send(
                :"#{setting}=",
                slice.application.config.views.public_send(:"#{setting}")
              )
            end
          end

          view_class.config.inflector = inflector
          view_class.config.paths = prepare_paths(slice, view_class.config.paths)
          view_class.config.template = template_name(view_class)

          if (part_namespace = namespace_from_path(slice.application.config.views.parts_path))
            view_class.config.part_namespace = part_namespace
          end
        end
        # rubocop:enable Metrics/AbcSize

        def define_inherited
          template_name = method(:template_name)

          define_method(:inherited) do |subclass|
            super(subclass)
            subclass.config.template = template_name.(subclass)
          end
        end

        def prepare_paths(slice, configured_paths)
          configured_paths.map { |path|
            if path.dir.relative?
              slice.root.join(path.dir)
            else
              path
            end
          }
        end

        def namespace_from_path(path)
          path = "#{slice.slice_name.path}/#{path}"

          begin
            require path
          rescue LoadError => exception
            raise exception unless exception.path == path
          end

          begin
            inflector.constantize(inflector.camelize(path))
          rescue NameError => exception
          end
        end

        def template_name(view_class)
          slice
            .inflector
            .underscore(view_class.name)
            .sub(/^#{slice.slice_name.path}\//, "")
            .sub(/^#{view_class.config.template_inference_base}\//, "")
        end

        def inflector
          slice.inflector
        end
      end
    end
  end
end
