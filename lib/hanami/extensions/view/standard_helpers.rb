# frozen_string_literal: true

module Hanami
  module Extensions
    module View
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
