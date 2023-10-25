# frozen_string_literal: true

require "hanami/action"

module Hanami
  # @api private
  module Extensions
    # Integrated behavior for `Hanami::Action` classes within Hanami apps.
    #
    # @see InstanceMethods
    # @see https://github.com/hanami/controller
    #
    # @api public
    # @since 2.0.0
    module Action
      # @api private
      def self.included(action_class)
        super

        action_class.extend(Hanami::SliceConfigurable)
        action_class.extend(ClassMethods)
        action_class.prepend(InstanceMethods)
      end

      # Class methods for app-integrated actions.
      #
      # @since 2.0.0
      module ClassMethods
        # @api private
        def configure_for_slice(slice)
          extend SliceConfiguredAction.new(slice)
        end
      end

      # Instance methods for app-integrated actions.
      #
      # @since 2.0.0
      module InstanceMethods
        # @api private
        attr_reader :view

        # @api private
        attr_reader :view_context_class

        # Returns the app or slice's {Hanami::Slice::RoutesHelper RoutesHelper} for use within
        # action instance methods.
        #
        # @return [Hanami::Slice::RoutesHelper]
        #
        # @api public
        # @since 2.0.0
        attr_reader :routes

        # Returns the app or slice's `Dry::Monitor::Rack::Middleware` for use within
        # action instance methods.
        #
        # @return [Dry::Monitor::Rack::Middleware]
        #
        # @api public
        # @since 2.0.0
        attr_reader :rack_monitor

        # @overload def initialize(routes: nil, **kwargs)
        #   Returns a new `Hanami::Action` with app components injected as dependencies.
        #
        #   These dependencies are injected automatically so that a call to `.new` (with no
        #   arguments) returns a fully integrated action.
        #
        #   @param routes [Hanami::Slice::RoutesHelper]
        #
        #   @api public
        #   @since 2.0.0
        def initialize(view: nil, view_context_class: nil, rack_monitor: nil, routes: nil, **kwargs)
          @view = view
          @view_context_class = view_context_class
          @routes = routes
          @rack_monitor = rack_monitor

          super(**kwargs)
        end

        private

        # @api private
        def build_response(**options)
          options = options.merge(view_options: method(:view_options))
          super(**options)
        end

        # @api private
        def finish(req, res, halted)
          res.render(view, **req.params) if !halted && auto_render?(res)
          super
        end

        # @api private
        def _handle_exception(request, _response, _exception)
          super
        rescue StandardError => exception
          rack_monitor&.instrument(:error, exception: exception, env: request.env)

          raise
        end

        # @api private
        def view_options(request, response)
          {context: view_context_class&.new(**view_context_options(request, response))}.compact
        end

        # @api private
        def view_context_options(request, response) # rubocop:disable Lint:UnusedMethodArgument
          {request: request}
        end

        # Returns true if a view should automatically be rendered onto the response body.
        #
        # This may be overridden to enable or disable automatic rendering.
        #
        # @param res [Hanami::Action::Response]
        #
        # @return [Boolean]
        #
        # @since 2.0.0
        # @api public
        def auto_render?(res)
          view && res.body.empty?
        end
      end
    end
  end
end

Hanami::Action.include(Hanami::Extensions::Action)
