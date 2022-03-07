# frozen_string_literal: true

require "hanami/action"
require "hanami/slice_configurable"

module Hanami
  class Application
    class Action < Hanami::Action
      # @api private
      class SliceConfiguredAction < Module
        attr_reader :slice

        def initialize(slice)
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

        # @see Hanami::Application::Action#initialize
        def define_new
          resolve_view = method(:resolve_paired_view)
          resolve_view_context = method(:resolve_view_context)
          resolve_routes = method(:resolve_routes)

          define_method(:new) do |**kwargs|
            super(
              view: kwargs.fetch(:view) { resolve_view.(self) },
              view_context: kwargs.fetch(:view_context) { resolve_view_context.(self) },
              routes: kwargs.fetch(:routes) { resolve_routes.() },
              **kwargs,
            )
          end
        end

        def configure_action(action_class)
          action_class.config.settings.each do |setting|
            action_class.config.public_send :"#{setting}=", actions_config.public_send(:"#{setting}")
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

        def actions_config
          slice.application.config.actions
        end

        def resolve_paired_view(action_class)
          view_identifiers = action_class.config.view_name_inferrer.call(
            action_name: action_class.name,
            provider: slice,
          )

          view_identifiers.detect do |identifier|
            break slice[identifier] if slice.key?(identifier)
          end
        end

        def resolve_view_context(action_class)
          identifier = action_class.config.view_context_identifier

          if slice.key?(identifier)
            slice[identifier]
          elsif slice.application.key?(identifier)
            # TODO: we might not need the fallback with the way we're setting up the view layer for slices now
            slice.application[identifier]
          end
        end

        def resolve_routes
          # TODO: turn this into a config
          slice.application[:routes_helper] if slice.application.key?(:routes_helper)
        end
      end
    end
  end
end
