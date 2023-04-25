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
          # TODO: remove these requires once hanami-view adopts Zeitwerk
          require "hanami/view/helpers/escape_helper"
          require "hanami/view/helpers/number_formatting_helper"
          require "hanami/view/helpers/tag_helper"

          klass.include Hanami::View::Helpers::EscapeHelper
          klass.include Hanami::View::Helpers::NumberFormattingHelper
          klass.include Hanami::View::Helpers::TagHelper
          klass.include Helpers::FormHelper
        end
      end
    end
  end
end
