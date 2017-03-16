require 'hanami'
require 'hanami/environment'
require 'hanami/components'
require 'concurrent'

module Hanami
  module Commands
    # Abstract command
    #
    # @since 0.9.0
    class Command
      # @since 0.9.0
      # @api private
      def self.inherited(component)
        super

        component.class_eval do
          @_requirements = Concurrent::Array.new
          extend ClassMethods
        end
      end

      # Class level interface
      #
      # @since 0.9.0
      # @api private
      module ClassMethods
        # @since 0.9.0
        # @api private
        def register_as(name)
          Hanami::Components.register(name, self)
        end

        # @since 0.9.0
        # @api private
        def requires(*names)
          requirements.concat(names)
        end

        # @since 0.9.0
        # @api private
        def requirements
          @_requirements
        end
      end

      # @param options [Hash] Environment's options
      #
      # @since 0.9.0
      # @api private
      def initialize(options)
        @environment = Hanami::Environment.new(options)
        @environment.require_project_environment
        @configuration = Hanami.configuration

        requirements.resolved('environment', environment)
        requirements.resolve(self.class.requirements)
      end

      private

      # @since 0.9.0
      # @api private
      attr_reader :environment

      # @since 0.9.0
      # @api private
      attr_reader :configuration

      # @since 0.9.0
      # @api private
      def requirements
        Hanami::Components
      end
    end
  end
end
