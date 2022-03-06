# frozen_string_literal: true

require "hanami/action"
require "hanami/slice_configurable"
require_relative "action/slice_configured_action"

module Hanami
  class Application
    class Action < Hanami::Action
      class Configuration < Hanami::Action::Configuration
        setting :view_name_inferrer
        setting :view_context_identifier
      end

      extend Hanami::SliceConfigurable

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
          extend SliceConfiguredAction.new(slice)
        end
      end

      attr_reader :view, :view_context, :routes

      # @see SliceConfiguredAction#define_new
      # @api public
      def initialize(view: nil, view_context: nil, routes: nil, **kwargs)
        @view = view
        @view_context = view_context
        @routes = routes

        super(**kwargs)
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
    end
  end
end
