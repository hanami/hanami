# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Configuration
    # NullConfiguration can serve as a fallback configuration object when out-of-gem
    # configuration objects are not available (specifically, when the hanami-controller or
    # hanami-view gems are not loaded)
    class NullConfiguration
      include Dry::Configurable
    end
  end
end
