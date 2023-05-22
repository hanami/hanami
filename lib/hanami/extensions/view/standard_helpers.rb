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
