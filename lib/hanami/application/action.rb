# frozen_string_literal: true

require "hanami/action"
require "hanami/slice_configurable_class"

module Hanami
  class Application
    class Action < Hanami::Action
      class Configuration < Hanami::Action::Configuration
        setting :view_name_inferrer
        setting :view_context_identifier
      end

      extend Hanami::SliceConfigurableClass

      class << self
        # @api public
        def configuration
          @configuration ||= Application::Action::Configuration.new
        end

        # FIXME: figure out why I actually need this given we have alias_method in the base class
        def config
          configuration
        end

        # @api private
        def configure_for_slice(slice)
          @slice = slice

          application_config = slice.application.config.actions

          configure_from_application_config(application_config)
          extend_behavior(application_config)
        end

        # @api private
        def slice
          @slice
        end

        # @api private
        def application
          slice.application
        end

        private

        def configure_from_application_config(application_config)
          config.settings.each do |setting|
            application_value = application_config.public_send(:"#{setting}")
            config.public_send :"#{setting}=", application_value
          end
        end

        def extend_behavior(application_config)
          # TODO: no op if ancestors already include these modules?

          if application_config.sessions.enabled?
            require "hanami/action/session"
            include Hanami::Action::Session
          end

          if application_config.csrf_protection
            require "hanami/action/csrf_protection"
            include Hanami::Action::CSRFProtection
          end

          if application_config.cookies.enabled?
            require "hanami/action/cookies"
            include Hanami::Action::Cookies
          end
        end
      end

      attr_reader :view, :view_context, :routes

      def initialize(
        view: resolve_paired_view,
        view_context: resolve_view_context,
        routes: resolve_routes,
        **dependencies
      )
        @view = view
        @view_context = view_context
        @routes = routes

        super(**dependencies)
      end

      def inspect
        "#<#{self.class.name}[#{self.class.slice.name}]>"
      end

      def build_response(**options)
        options = options.merge(view_options: method(:view_options))
        super(**options)
      end

      def view_options(req, res)
        {context: view_context&.with(**view_context_options(req, res))}.compact
      end

      def view_context_options(req, res)
        {request: req, response: res}
      end

      def finish(req, res, halted)
        res.render(view, **req.params) if render?(res)
        super
      end

      # Decide whether to render the current response with the associated view.
      # This can be overridden to enable/disable automatic rendering.
      #
      # @param res [Hanami::Action::Response]
      #
      # @return [TrueClass,FalseClass]
      #
      # @since 2.0.0
      # @api public
      def render?(res)
        view && res.body.empty?
      end

      private

      def resolve_paired_view
        # There's a lot of class-level things going on... and no instance-level state
        # required... I wonder if this can move to the class level

        # Is `config` injected to the instance with actions? It might be, meaning I don't
        # have to reach to the class for it
        view_identifiers = self.class.config.view_name_inferrer.call(
          action_name: self.class.name,
          provider: self.class.slice,
        )

        view_identifiers.detect do |identifier|
          break self.class.slice[identifier] if self.class.slice.key?(identifier)
        end
      end

      def resolve_view_context
        identifier = self.class.config.view_context_identifier

        if self.class.slice.key?(identifier)
          self.class.slice[identifier]
        elsif self.class.application.key?(identifier)
          # TODO: we might not need the fallback with the way we're setting up the view layer for slices now
          self.class.application[identifier]
        end
      end

      def resolve_routes
        # TODO: turn this into a config
        self.class.application[:routes_helper] if self.class.application.key?(:routes_helper)
      end
    end
  end
end
