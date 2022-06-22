# frozen_string_literal: true

require "hanami/action"
require_relative "../slice_configurable"
require_relative "action/slice_configured_action"

module Hanami
  module Extensions
    # Extended behavior for actions intended for use within an Hanami application.
    #
    # @see Hanami::Action
    #
    # @api public
    # @since 2.0.0
    module Action
      def self.included(action_class)
        super

        action_class.extend(Hanami::SliceConfigurable)
        action_class.extend(ClassMethods)
        action_class.prepend(InstanceMethods)
      end

      module ClassMethods
        def configure_for_slice(slice)
          extend SliceConfiguredAction.new(slice)
        end
      end

      module InstanceMethods
        attr_reader :view, :view_context, :routes

        def initialize(view: nil, view_context: nil, routes: nil, **kwargs)
          @view = view
          @view_context = view_context
          @routes = routes

          super(**kwargs)
        end

        private

        def build_response(**options)
          options = options.merge(view_options: method(:view_options))
          super(**options)
        end

        def finish(req, res, halted)
          res.render(view, **req.params) if !halted && auto_render?(res)
          super
        end

        def view_options(req, res)
          {context: view_context&.with(**view_context_options(req, res))}.compact
        end

        def view_context_options(req, res)
          {request: req, response: res}
        end

        # Returns true if a view should automatically be rendered onto the response body.
        #
        # This may be overridden to enable/disable automatic rendering.
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
