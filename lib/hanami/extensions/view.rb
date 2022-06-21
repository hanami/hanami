# frozen_string_literal: true

require "hanami/view"
require_relative "../slice_configurable"
require_relative "view/slice_configured_view"

module Hanami
  module Extensions
    # Extended behavior for actions intended for use within an Hanami application.
    #
    # @see Hanami::View
    #
    # @api public
    # @since 2.0.0
    module View
      def self.included(view_class)
        super

        view_class.extend(Hanami::SliceConfigurable)
        view_class.extend(ClassMethods)
      end

      module ClassMethods
        # @api private
        def configure_for_slice(slice)
          extend SliceConfiguredView.new(slice)
        end
      end
    end
  end
end

Hanami::View.include(Hanami::Extensions::View)
