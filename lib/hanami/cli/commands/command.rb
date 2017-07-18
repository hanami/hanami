require 'hanami'
require 'hanami/environment'
require 'hanami/components'
require 'hanami/cli/command'
require 'concurrent'
require 'hanami/utils/files'
require 'erb'

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
              environment = Hanami::Environment.new(options)
              environment.require_project_environment

              requirements.resolved('environment', environment)
              requirements.resolve(self.class.requirements)

              options = environment.to_options.merge(options)
            end

            super(options)
          end
        end

        def initialize(out: $stdout, files: Utils::Files)
          @out   = out
          @files = files
        end

        private

        class Renderer
          TRIM_MODE = "-".freeze

          def initialize
            freeze
          end

          def call(template, context)
            ::ERB.new(template, nil, TRIM_MODE).result(context)
          end
        end

        SAY_FORMATTER = "%<operation>12s  %<path>s\n".freeze

        attr_reader :out, :files

        def render(path, context)
          template = File.read(path)
          renderer = Renderer.new

          renderer.call(template, context.binding)
        end

        def generate_file(source, destination, context)
          files.write(
            destination,
            render(source, context)
          )
        end

        def say(operation, path)
          out.puts(SAY_FORMATTER % { operation: operation, path: path })
        end

        # @since 0.9.0
        # @api private
        def requirements
          Hanami::Components
        end
      end
    end
  end
end
