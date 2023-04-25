# frozen_string_literal: true

# TODO: remove these requires once hanami-view adopts Zeitwerk
require "hanami/view/helpers/escape_helper"
require "hanami/view/helpers/number_formatting_helper"
require "hanami/view/helpers/tag_helper"

module Hanami
  module Extensions
    module View
      module StandardHelpers
        include Hanami::View::Helpers::EscapeHelper
        include Hanami::View::Helpers::NumberFormattingHelper
        include Hanami::View::Helpers::TagHelper
        include Helpers::FormHelper
      end
    end
  end
end
