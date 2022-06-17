# frozen_string_literal: true

require "hanami/view"
require_relative "../slice_configurable"
require_relative "view/slice_configured_view"

module Hanami
  class Application
    # Superclass for views intended for use within an Hanami application.
    #
    # @see Hanami::View
    #
    # @api public
    # @since 2.0.0
    class View < Hanami::View
      extend Hanami::SliceConfigurable

      # @api private
      def self.configure_for_slice(slice)
        extend SliceConfiguredView.new(slice)
      end
    end
  end
end
