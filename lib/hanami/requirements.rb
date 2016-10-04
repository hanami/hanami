require 'hanami/components'

module Hanami
  # Components requirements
  #
  # @since x.x.x
  class Requirements
    def initialize(requirements)
      @requirements = Array(requirements).flatten
      @components   = Components.resolve(@requirements)
    end

    def [](component)
      components.fetch(component)
    end

    private

    attr_reader :components
  end
end
