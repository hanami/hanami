# frozen_string_literal: true

require "hanami/view"

module Hanami
  # @api private
  module Extensions
    # Integrated behavior for `Hanami::View` classes within Hanami apps.
    #
    # @see Hanami::View
    #
    # @api public
    # @since 2.1.0
    module View
      # @api private
      # @since 2.1.0
      def self.included(view_class)
        super

        view_class.extend(Hanami::SliceConfigurable)
        view_class.extend(ClassMethods)
      end

      # @api private
      # @since 2.1.0
      module ClassMethods
        # @api private
        # @since 2.1.0
        def configure_for_slice(slice)
          extend SliceConfiguredView.new(slice)
        end
      end
    end
  end
end

Hanami::View.include(Hanami::Extensions::View)
