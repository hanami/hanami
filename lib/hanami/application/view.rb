# frozen_string_literal: true

require "hanami/view"
require "hanami/slice_configurable"
require_relative "view/slice_configured_view"

module Hanami
  class Application
    class View < Hanami::View
      extend Hanami::SliceConfigurable

      def self.configure_for_slice(slice)
        extend SliceConfiguredView.new(slice)
      end
    end
  end
end
