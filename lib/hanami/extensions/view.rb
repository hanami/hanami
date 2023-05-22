require "hanami/view"

module Hanami
  # @api private
  module Extensions
    # Integrated behavior for `Hanami::View` classes within Hanami apps.
    #
    # This is NOT RELEASED as of 2.0.0.
    #
    # @see Hanami::View
    #
    # @api private
    module View
      # @api private
      def self.included(view_class)
        super

        view_class.extend(Hanami::SliceConfigurable)
        view_class.extend(ClassMethods)
      end

      # @api private
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
