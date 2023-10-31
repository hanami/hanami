# frozen_string_literal: true

module Hanami
  module Extensions
    module Action
      # Provides slice-specific configuration and behavior for any action class defined
      # within a slice's module namespace.
      #
      # @api private
      # @since 2.0.0
      class SliceConfiguredAction < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(action_class)
          configure_action(action_class)
          extend_behavior(action_class)
          define_new
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        # @see Hanami::Extensions::Action::InstanceMethods#initialize
        def define_new
          resolve_view = method(:resolve_paired_view)
          view_context_class = method(:view_context_class)
          resolve_routes = method(:resolve_routes)
          resolve_rack_monitor = method(:resolve_rack_monitor)

          define_method(:new) do |**kwargs|
            super(
              view: kwargs.fetch(:view) { resolve_view.(self) },
              view_context_class: kwargs.fetch(:view_context_class) { view_context_class.() },
              routes: kwargs.fetch(:routes) { resolve_routes.() },
              rack_monitor: kwargs.fetch(:rack_monitor) { resolve_rack_monitor.() },
              **kwargs,
            )
          end
        end

        def configure_action(action_class)
          action_class.settings.each do |setting|
            # Configure the action from config on the slice, _unless it has already been configured
            # by a parent slice_, and re-configuring it for this slice would make no change.
            #
            # In the case of most slices, its actions config is likely to be the same as its parent
            # (since each slice copies its `config` from its parent), and if we re-apply the config
            # here, then it may possibly overwrite config customisations explicitly made in parent
            # action classes.
            #
            # For example, given an app-level base action class, with custom config:
            #
            #   module MyApp
            #     class Action < Hanami::Action
            #       config.format :json
            #     end
            #   end
            #
            # And then an action in a slice inheriting from it:
            #
            #   module MySlice
            #     module Actions
            #       class SomeAction < MyApp::Action
            #       end
            #     end
            #   end
            #
            # In this case, `SliceConfiguredAction` will be extended two times:
            #
            # 1. When `MyApp::Action` is defined
            # 2. Again when `MySlice::Actions::SomeAction` is defined
            #
            # If we blindly re-configure all action settings each time `SliceConfiguredAction` is
            # extended, then at the point of (2) above, we'd end up overwriting the custom
            # `config.default_response_format` explicitly configured in the `MyApp::Action` base
            # class, leaving `MySlice::Actions::SomeAction` with `config.default_response_format` of
            # `:html` (the default at `Hanami.app.config.actions.default_response_format`), and not
            # the `:json` value configured in its immediate superclass.
            #
            # This would be surprising behavior, and we want to avoid it.
            slice_value = slice.config.actions.public_send(setting.name)
            parent_value = slice.parent.config.actions.public_send(setting.name) if slice.parent

            next if slice.parent && slice_value == parent_value

            action_class.config.public_send(
              :"#{setting.name}=",
              setting.mutable? ? slice_value.dup : slice_value
            )
          end
        end

        def extend_behavior(action_class)
          if actions_config.sessions.enabled?
            require "hanami/action/session"
            action_class.include Hanami::Action::Session
          end

          if actions_config.csrf_protection
            require "hanami/action/csrf_protection"
            action_class.include Hanami::Action::CSRFProtection
          end

          if actions_config.cookies.enabled?
            require "hanami/action/cookies"
            action_class.include Hanami::Action::Cookies
          end
        end

        def resolve_paired_view(action_class)
          view_identifiers = actions_config.view_name_inferrer.call(
            action_class_name: action_class.name,
            slice: slice,
          )

          view_identifiers.each do |identifier|
            return slice[identifier] if slice.key?(identifier)
          end

          nil
        end

        def view_context_class
          if Hanami.bundled?("hanami-view")
            return Extensions::View::Context.context_class(slice)
          end

          # If hanami-view isn't bundled, try and find a possible third party context class with the
          # same `Views::Context` name (but don't fall back to automatically defining one).
          if slice.namespace.const_defined?(:Views)
            views_namespace = slice.namespace.const_get(:Views)

            if views_namespace.const_defined?(:Context)
              views_namespace.const_get(:Context)
            end
          end
        end

        def resolve_routes
          slice.app["routes"] if slice.app.key?("routes")
        end

        def resolve_rack_monitor
          slice.app["rack.monitor"] if slice.app.key?("rack.monitor")
        end

        def actions_config
          slice.config.actions
        end
      end
    end
  end
end
