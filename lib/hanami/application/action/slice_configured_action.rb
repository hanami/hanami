# frozen_string_literal: true

require "hanami/action"

module Hanami
  class Application
    class Action < Hanami::Action
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

        def resolve_paired_view(action_class)
          view_identifiers = actions_config.view_name_inferrer.call(
            action_class_name: action_class.name,
            slice: slice,
          )

          view_identifiers.detect do |identifier|
            break slice[identifier] if slice.key?(identifier)
          end
        end

        def resolve_view_context(_action_class)
          identifier = actions_config.view_context_identifier

          if slice.key?(identifier)
            slice[identifier]
          elsif slice.application.key?(identifier)
            slice.application[identifier]
          end
        end

        def resolve_routes
          slice.application[:routes_helper] if slice.application.key?(:routes_helper)
        end

        def actions_config
          slice.application.config.actions
        end
      end
    end
  end
end
