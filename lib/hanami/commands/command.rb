require 'hanami'
require 'hanami/environment'
require 'hanami/components'
require 'concurrent'

module Hanami
  module Commands
    # Abstract command
    #
    # @since x.x.x
    class Command
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

      # @param options [Hash] Environment's options
      #
      # @since x.x.x
      def initialize(options)
        @environment = Hanami::Environment.new(options)
        @environment.require_project_environment
        @configuration = Hanami.configuration

        requirements.resolved('environment', environment)
        requirements.resolve(self.class.requirements)
      end

      private

      # @since x.x.x
      attr_reader :environment

      # @since x.x.x
      attr_reader :configuration

      # @since x.x.x
      def requirements
        Hanami::Components
      end
    end
  end
end
