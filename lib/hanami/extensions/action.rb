# frozen_string_literal: true

require "hanami/action"

module Hanami
  module Extensions
    module Action
      def self.included(base_action)
        super
        base_action.extend(ClassMethods)
      end

      module ClassMethods
        # def configure_for_slice(slice)
        #   extend SliceConfiguredAction.new(slice)
        # end
      end

      attr_reader :view, :view_context, :routes

      private

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

Hanami::Action.include(Hanami::Extensions::Action)
