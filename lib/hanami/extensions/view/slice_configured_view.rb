# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # Provides slice-specific configuration and behavior for any view class defined within a
      # slice's module namespace.
      #
      # @api public
      # @since 2.1.0
      class SliceConfiguredView < Module
        TEMPLATES_DIR = "templates"
        VIEWS_DIR = "views"
        PARTS_DIR = "parts"
        SCOPES_DIR = "scopes"

        attr_reader :slice

        # @api private
        # @since 2.1.0
        def initialize(slice)
          super()
          @slice = slice
        end

        # @api private
        # @since 2.1.0
        def extended(view_class)
          load_app_view
          configure_view(view_class)
          define_inherited
        end

        # @return [String]
        #
        # @api public
        # @since 2.1.0
        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        # If the given view doesn't inherit from the app view, attempt to load it anyway, since
        # requiring the app view is necessary for _its_ `SliceConfiguredView` hook to execute and
        # define the app-level part and scope classes that we refer to here.
        def load_app_view
          return if app?

          begin
            slice.app.namespace.const_get(:View, false)
          rescue NameError => e
            raise unless e.name == :View
          end
        end

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

            view_class.config.public_send(
              :"#{setting.name}=",
              setting.mutable? ? slice_value.dup : slice_value
            )
          end

          view_class.config.inflector = inflector

          # Configure the paths for this view if:
          #   - We are the app, and a user hasn't provided custom `paths` (in this case, we need to
          #     set the defaults)
          #   - We are a slice, and the view's inherited `paths` is identical to the parent's config
          #     (which would result in the view in a slice erroneously trying to find templates in
          #     the app)
          if view_class.config.paths.empty? ||
             (slice.parent && view_class.config.paths.map(&:dir) == [templates_path(slice.parent)])
            view_class.config.paths = templates_path(slice)
          end

          view_class.config.template = template_name(view_class)
          view_class.config.default_context = Extensions::View::Context.context_class(slice).new

          view_class.config.part_class = part_class
          view_class.config.scope_class = scope_class

          if (part_namespace = namespace_from_path("#{VIEWS_DIR}/#{PARTS_DIR}"))
            view_class.config.part_namespace = part_namespace
          end
          if (scope_namespace = namespace_from_path("#{VIEWS_DIR}/#{SCOPES_DIR}"))
            view_class.config.scope_namespace = scope_namespace
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

        def templates_path(slice)
          if slice.app.equal?(slice)
            slice.root.join(APP_DIR, TEMPLATES_DIR)
          else
            slice.root.join(TEMPLATES_DIR)
          end
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
          inflector
            .underscore(view_class.name)
            .sub(/^#{slice.slice_name.path}\//, "")
            .sub(/^#{VIEWS_DIR}\//, "")
        end

        def inflector
          slice.inflector
        end

        def part_class
          @part_class ||=
            if views_namespace.const_defined?(:Part)
              views_namespace.const_get(:Part)
            else
              views_namespace.const_set(:Part, Class.new(part_superclass).tap { |klass|
                # Give the slice to `configure_for_slice`, since it cannot be inferred when it is
                # called via `.inherited`, because the class is anonymous at this point
                klass.configure_for_slice(slice)
              })
            end
        end

        def part_superclass
          return Hanami::View::Part if app?

          begin
            inflector.constantize(inflector.camelize("#{slice.app.slice_name.name}/views/part"))
          rescue NameError
            Hanami::View::Part
          end
        end

        def scope_class
          @scope_class ||=
            if views_namespace.const_defined?(:Scope)
              views_namespace.const_get(:Scope)
            else
              views_namespace.const_set(:Scope, Class.new(scope_superclass).tap { |klass|
                # Give the slice to `configure_for_slice`, since it cannot be inferred when it is
                # called via `.inherited`, since the class is anonymous at this point
                klass.configure_for_slice(slice)
              })
            end
        end

        def scope_superclass
          return Hanami::View::Scope if app?

          begin
            inflector.constantize(inflector.camelize("#{slice.app.slice_name.name}/views/scope"))
          rescue NameError
            Hanami::View::Scope
          end
        end

        def views_namespace
          @slice_views_namespace ||=
            if slice.namespace.const_defined?(:Views)
              slice.namespace.const_get(:Views)
            else
              slice.namespace.const_set(:Views, Module.new)
            end
        end

        def app?
          slice.app == slice
        end
      end
    end
  end
end
