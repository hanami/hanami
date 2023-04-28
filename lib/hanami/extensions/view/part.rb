# frozen_string_literal: true

require "hanami/view"
require "hanami/view/part"

module Hanami
  module Extensions
    module View
      # @api private
      module Part
        def self.included(part_class)
          super

          part_class.extend(Hanami::SliceConfigurable)
          part_class.include(StandardHelpers)
          part_class.extend(ClassMethods)
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

Hanami::View::Part.include(Hanami::Extensions::View::Part)
