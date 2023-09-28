# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Config
    # NullConfig can serve as a fallback config object when out-of-gem config objects are not
    # available (specifically, when the hanami-controller, hanami-router or hanami-view gems are not
    # loaded)
    class NullConfig
      include Dry::Configurable

      def finalize!(*)
      end
    end
  end
end
