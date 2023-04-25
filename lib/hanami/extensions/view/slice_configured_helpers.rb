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
          if mod = helpers_module(slice.app)
            klass.include(mod)
          end

          if mod = helpers_module(slice)
            klass.include(mod)
          end
        end

        def helpers_module(slice)
          return unless slice.namespace.const_defined?(:Views)
          return unless slice.namespace.const_get(:Views).const_defined?(:Helpers)

          slice.namespace.const_get(:Views).const_get(:Helpers)
        end
      end
    end
  end
end
