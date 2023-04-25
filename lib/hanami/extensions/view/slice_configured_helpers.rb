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

        def include_helpers(klass)
          require "hanami/helpers/example_helper"
          klass.include Helpers::ExampleHelper

          require "hanami/helpers/form_helper"
          klass.include Helpers::FormHelper
        end
      end
    end
  end
end
