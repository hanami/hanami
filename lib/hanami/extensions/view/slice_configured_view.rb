# frozen_string_literal: true

require "hanami/view"

module Hanami
  module Extensions
    module View
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
            next unless slice.config.views.respond_to?(setting.name)

            # Configure the view from config on the slice, _unless it has already been configured by
            # a parent slice_, and re-configuring it for this slice would make no change.
            #
            # In the case of most slices, its views config is likely to be the same as its parent
            # (since each slice copies its `config` from its parent), and if we re-apply the config
            # here, then it may possibly overwrite config customisations explicitly made in parent
            # view classes.
            #
            # For example, given an app-level base view class, with custom config:
            #
            #   module MyApp
            #     class View < Hanami::View
            #       config.layout = "custom_layout"
            #     end
            #   end
            #
            # And then a view in a slice inheriting from it:
            #
            #   module MySlice
            #     module Views
            #       class SomeView < MyApp::View
            #       end
            #     end
            #   end
            #
            # In this case, `SliceConfiguredView` will be extended two times:
            #
            # 1. When `MyApp::View` is defined
            # 2. Again when `MySlice::Views::SomeView` is defined
            #
            # If we blindly re-configure all view settings each time `SliceConfiguredView` is
            # extended, then at the point of (2) above, we'd end up overwriting the custom
            # `config.layout` explicitly configured in the `MyApp::View` base class, leaving
            # `MySlice::Views::SomeView` with `config.layout` of `"app"` (the default as specified
            # at `Hanami.app.config.views.layout`), and not the `"custom_layout"` value configured
            # in its immediate superclass.
            #
            # This would be surprising behavior, and we want to avoid it.
            slice_value = slice.config.views.public_send(setting.name)
            parent_value = slice.parent.config.views.public_send(setting.name) if slice.parent

            next if slice.parent && slice_value == parent_value

            view_class.config.public_send(:"#{setting.name}=", slice_value)
          end

          view_class.config.inflector = inflector
          view_class.config.paths = prepare_paths(slice, view_class.config.paths)
          view_class.config.template = template_name(view_class)

          if (part_namespace = namespace_from_path(slice.config.views.parts_path))
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
              if slice.app.equal?(slice)
                # App-level templates are in app/
                slice.root.join(APP_DIR, path.dir)
              else
                # Other slice templates are in the root slice dir
                slice.root.join(path.dir)
              end
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
          rescue NameError # rubocop: disable Lint/SuppressedException
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
