# frozen_string_literal: true

require "hanami/action"
require "hanami/slice_configurable"
require_relative "action/slice_configured_action"

module Hanami
  class Application
    # Superclass for actions intended for use within an Hanami application.
    #
    # @see Hanami::Action
    #
    # @api public
    # @since 2.0.0
    class Action < Hanami::Action
      extend Hanami::SliceConfigurable

      class << self
        # @api private
        def configure_for_slice(slice)
          extend SliceConfiguredAction.new(slice)
        end
      end

      # @see SliceConfiguredAction#define_new
      # @api public
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
    end
  end
end
