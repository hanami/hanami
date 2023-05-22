module Hanami
  module Extensions
    module View
      # @api private
      module Scope
        def self.included(scope_class)
          super

          scope_class.extend(Hanami::SliceConfigurable)
          scope_class.include(StandardHelpers)
          scope_class.extend(ClassMethods)
        end

        module ClassMethods
          def configure_for_slice(slice)
            extend SliceConfiguredHelpers.new(slice)
          end
        end
      end
    end
  end
end

Hanami::View::Scope.include(Hanami::Extensions::View::Scope)
