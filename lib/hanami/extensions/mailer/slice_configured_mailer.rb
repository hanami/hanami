# frozen_string_literal: true

module Hanami
  module Extensions
    module Mailer
      # Provides slice-specific configuration and behavior for any mailer class defined within a
      # slice's module namespace.
      #
      # This injects the slice's `"mailers.delivery_method"` component into mailer instances, and
      # points the mailer's view at a slice-configured view class so that mailer templates behave
      # like regular Hanami view templates — sharing the slice's view context, parts, scopes and
      # helpers (including i18n). The only behavior not available to mailer views is
      # request-related state (`request`/`session`/`flash`/`csrf_token`), since mailers are not
      # rendered from a request.
      #
      # @api private
      class SliceConfiguredMailer < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(mailer_class)
          configure_mailer(mailer_class)
          define_new
          define_inherited
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        def define_new
          resolve_delivery_method = method(:resolve_delivery_method)

          define_method(:new) do |**kwargs|
            super(
              delivery_method: kwargs.fetch(:delivery_method) { resolve_delivery_method.() },
              **kwargs
            )
          end
        end

        # Reconfigures the template name for each subclass.
        def define_inherited
          template_name = method(:template_name)

          define_method(:inherited) do |subclass|
            super(subclass)

            if (template = template_name.(subclass))
              subclass.config.template = template
            end
          end
        end

        def resolve_delivery_method
          slice["mailers.delivery_method"] if slice.key?("mailers.delivery_method")
        end

        def configure_mailer(mailer_class)
          return unless Hanami.bundled?("hanami-view")

          # Build the mailer's view from a slice-configured view class, so it inherits the slice's
          # context, parts, scopes, paths and helpers. The mailer only needs to supply its own
          # template name.
          mailer_class.config.view_class = mailer_view_class

          if (template = template_name(mailer_class))
            mailer_class.config.template = template
          end
        end

        # Returns the view class that mailer views are built from, defining a `Mailers::View` within
        # the slice if one is not already present.
        #
        # This mirrors how the view extension defines a `Views::Context`: because the class is
        # defined within the slice's namespace, it is configured automatically (paths, context,
        # parts, scopes, helpers) just like any other view in the slice. A user may define their own
        # `<Slice>::Mailers::View` to customize mailer rendering; it is used when present.
        def mailer_view_class
          namespace = mailers_namespace

          if namespace.const_defined?(:View, _inherit = false)
            namespace.const_get(:View)
          else
            namespace.const_set(:View, define_mailer_view)
          end
        end

        # Defines and configures a view class for the slice's mailers, inheriting from the slice's
        # own base view class if present, otherwise from the plain `Hanami::View`.
        def define_mailer_view
          superclass =
            begin
              slice.inflector.constantize("#{slice.namespace.name}::View")
            rescue NameError
              Hanami::View
            end

          Class.new(superclass).tap { |klass|
            # Call configure_for_slice explicitly, since this is an anonymous class at this point,
            # so the slice cannot be inferred from its name.
            klass.configure_for_slice(slice)
          }
        end

        def mailers_namespace
          if slice.namespace.const_defined?(:Mailers, _inherit = false)
            slice.namespace.const_get(:Mailers)
          else
            slice.namespace.const_set(:Mailers, Module.new)
          end
        end

        # Returns the template name for the mailer, retaining the `mailers/` segment from the
        # mailer's namespace so templates resolve under `templates/mailers/` within the slice.
        #
        # For example, `App::Mailers::Welcome` will use template `"mailers/welcome"`.
        def template_name(mailer_class)
          return unless mailer_class.name

          slice.inflector
            .underscore(mailer_class.name)
            .sub(/^#{slice.slice_name.path}\//, "")
        end
      end
    end
  end
end
