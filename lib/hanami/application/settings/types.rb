# frozen_string_literal: true

require "dry-types"

module Hanami
  class Application
    module Settings
      # Application settings types
      #
      # @since 2.0.0
      module Types
        include Dry::Types()
      end
    end
  end
end
