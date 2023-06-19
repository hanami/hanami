# frozen_string_literal: true

module Hanami
  module Helpers
    module AssetsHelper
      def javascript(...)
        _context.assets.javascript(...)
      end
    end
  end
end
