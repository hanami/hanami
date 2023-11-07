# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # @api private
      # @since 2.1.0
      module Scope
        # @api private
        # @since 2.1.0
        def self.included(scope_class)
          super

          scope_class.extend(Hanami::SliceConfigurable)
          scope_class.include(StandardHelpers)
          scope_class.extend(ClassMethods)
        end

        # @api private
        # @since 2.1.0
        module ClassMethods
          # @api private
          # @since 2.1.0
          def configure_for_slice(slice)
            extend SliceConfiguredHelpers.new(slice)
          end
        end
      end
    end
  end
end

Hanami::View::Scope.include(Hanami::Extensions::View::Scope)
