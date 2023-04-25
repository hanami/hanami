# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # @api private
      class SliceConfiguredHelpers < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(klass)
          include_helpers(klass)
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        def include_helpers(klass)
          klass.include(slice_helpers_module) if slice_helpers_module
        end

        def slice_helpers_module
          if views_namespace.const_defined?(:Helpers)
            views_namespace.const_get(:Helpers)
          end
        end

        def views_namespace
          @views_namespace ||=
            if slice.namespace.const_defined?(:Views)
              slice.namespace.const_get(:Views)
            else
              slice.namespace.const_set(:Views, Module.new)
            end
        end
      end
    end
  end
end
