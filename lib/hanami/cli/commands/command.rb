require 'hanami'
require 'hanami/environment'
require 'hanami/components'
require 'hanami/cli/command'
require 'concurrent'

module Hanami
  module Cli
    module Commands
      # Abstract command
      #
      # @since 0.9.0
      class Command < Hanami::Cli::Command
        # @since 0.9.0
        # @api private
        def self.inherited(component)
          super

          component.class_eval do
            @_requirements = Concurrent::Array.new
            extend ClassMethods
            prepend InstanceMethods
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

        module InstanceMethods
          def call(**options)
            if self.class.requirements.any?
              @environment = Hanami::Environment.new(options)
              @environment.require_project_environment
              @configuration = Hanami.configuration

              requirements.resolved('environment', environment)
              requirements.resolve(self.class.requirements)
            end

            super
          end
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
end
