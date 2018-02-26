require 'hanami'
require 'hanami/environment'
require 'hanami/components'
require 'hanami/cli/command'
require 'hanami/cli/commands/project'
require 'hanami/cli/commands/templates'
require 'concurrent'
require 'hanami/utils/files'
require 'hanami/utils/shell_code'
require 'erb'

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # Abstract command
      #
      # @since 1.1.0
      class Command < Hanami::CLI::Command
        # @since 1.1.0
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
        # @since 1.1.0
        module ClassMethods
          # Requires an internal Hanami component
          #
          # @param names [Array<String>] the name of one or more components
          #
          # @since 1.1.0
          #
          # @example
          #   require "hanami/cli/commands"
          #
          #   module HanamiDatabaseHelpers
          #     class TruncateTables < Hanami::CLI::Commands::Command
          #       requires "model.configuration"
          #
          #       def call(*)
          #         url = requirements["model.configuration"].url
          #         # ...
          #       end
          #     end
          #   end
          #
          #   Hanami::CLI.register "db truncate", HanamiDatabaseHelpers::TruncateTables
          def requires(*names)
            requirements.concat(names)
          end

          # @since 1.1.0
          # @api private
          def requirements
            @_requirements
          end
        end

        # @since 1.1.0
        # @api private
        module InstanceMethods
          # @since 1.1.0
          # @api private
          def call(**options)
            if self.class.requirements.any?
              environment = Hanami::Environment.new(options)
              environment.require_project_environment

              requirements.resolved('environment', environment)
              requirements.resolve(self.class.requirements)

              options = environment.to_options.merge(options)
            end

            super(options)
          rescue StandardError => e
            warn e.message
            exit(1)
          end
        end

        # @since 1.1.0
        # @api private
        def initialize(command_name:, out: $stdout, files: Utils::Files)
          super(command_name: command_name)

          @out       = out
          @files     = files
          @templates = Templates.new(self.class)
        end

        private

        # Template renderer
        #
        # @since 1.1.0
        # @api private
        class Renderer
          # @since 1.1.0
          # @api private
          TRIM_MODE = "-".freeze

          # @since 1.1.0
          # @api private
          def initialize
            freeze
          end

          # @since 1.1.0
          # @api private
          def call(template, context)
            ::ERB.new(template, nil, TRIM_MODE).result(context)
          end
        end

        # @since x.x.x
        # @api private
        COLUMN_WIDTH = 12

        # @since x.x.x
        # @api private
        EXTRA_COLORIZE_WIDTH = 9

        # @since x.x.x
        # @api private
        OPERATION_COLORS = Hash[
          create: :green,
          remove: :red,
          insert: :blue,
          append: :cyan,
          run:    :magenta,
        ].freeze

        # @since 1.1.0
        # @api private
        attr_reader :out

        # @since 1.1.0
        # @api private
        attr_reader :files

        # @since 1.1.0
        # @api private
        attr_reader :templates

        # @since 1.1.0
        # @api private
        def render(path, context)
          template = File.read(path)
          renderer = Renderer.new

          renderer.call(template, context.binding)
        end

        # @since 1.1.0
        # @api private
        def generate_file(source, destination, context)
          files.write(
            destination,
            render(source, context)
          )
        end

        # @since 1.1.0
        # @api private
        def say(operation, path)
          out.puts(_format_say(operation, path))
        end

        # @since x.x.x
        # @api private
        def _format_say(operation, path)
        [
          _colorize_operation(operation),
          path
        ].join("  ")
        end

        # @since x.x.x
        # @api private
        def _colorize_operation(operation)
          if OPERATION_COLORS.key?(operation)
            _colorize_and_justify(operation)
          else
            operation.to_s.rjust(COLUMN_WIDTH)
          end
        end

        # @since 1.1.0
        # @api private
        def project
          Project
        end

        # @since 1.1.0
        # @api private
        def requirements
          Hanami::Components
        end

        # @since x.x.x
        # @api private
        def _colorize_and_justify(operation)
          color = OPERATION_COLORS.fetch(operation)
          # Colorize adds 9 characters. They're not visible but Ruby doesn't
          # know that, so we have to compensate.
          Hanami::Utils::ShellCode.colorize(operation, color: color)
                                  .rjust(COLUMN_WIDTH + EXTRA_COLORIZE_WIDTH)
        end
      end
    end
  end
end
