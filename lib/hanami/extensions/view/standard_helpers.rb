# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # Module including the standard library of Hanami helpers
      #
      # @api public
      # @since 2.1.0
      module StandardHelpers
        include Hanami::View::Helpers::EscapeHelper
        include Hanami::View::Helpers::NumberFormattingHelper
        include Hanami::View::Helpers::TagHelper
        include Helpers::FormHelper

        if Hanami.bundled?("hanami-assets")
          include Helpers::AssetsHelper
        end
      end
    end
  end
end
