require 'concurrent'

module Hanami
  # Base component
  #
  # @since x.x.x
  class Component
    def self.inherited(component)
      super

      component.class_eval do
        @_requirements = Concurrent::Array.new
        extend ClassMethods
      end
    end

    # Class level interface
    #
    # @since x.x.x
    module ClassMethods
      def register_as(name)
        Hanami::Components.register(name, self)
      end

      def requires(*names)
        requirements.concat(names)
      end

      def requirements
        @_requirements
      end
    end

    # @param configuration [Hanami::Configuration]
    #
    # @since x.x.x
    def initialize(configuration)
      @configuration = configuration
      requirements.resolve(self.class.requirements)
    end

    # @since x.x.x
    def resolve
      raise NotImplementedError
    end

    private

    # @since x.x.x
    attr_reader :configuration

    # @since x.x.x
    def requirements
      Hanami::Components
    end
  end
end
