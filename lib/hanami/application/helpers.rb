# frozen_string_literal: true

require "hanami/helpers"
require "dry/core/basic_object"

module Hanami
  class Application
    class Helpers < Dry::Core::BasicObject
      include Hanami::Helpers
    end
  end
end
