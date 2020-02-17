# frozen_string_literal: true

require "hanami"
require "dry/cli/command"
require "concurrent"
require "hanami/utils/files"
require "erb"

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # Abstract command
      #
      # @since 1.1.0
      class Command < Dry::CLI::Command
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
            # FIXME: merge ENV vars (like HANAMI_ENV) into **options
            super(options)
          rescue StandardError => exception
            warn exception.message
            warn exception.backtrace.join("\n\t")
            exit(1)
          end
        end

        # @since 1.1.0
        # @api private
        def initialize(command_name:, out: $stdout, files: Utils::Files)
          super(command_name: command_name)

          @out   = out
          @files = files
        end

        private

        # Template renderer
        #
        # @since 1.1.0
        # @api private
        class Renderer
          # @since 1.1.0
          # @api private
          TRIM_MODE = "-"

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

        # @since 1.1.0
        # @api private
        SAY_FORMATTER = "%<operation>12s  %<path>s\n"

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
          out.puts(SAY_FORMATTER % { operation: operation, path: path }) # rubocop:disable Style/FormatString
        end

        # @since 1.1.0
        # @api private
        def project
          # FIXME: is this still useful?
          raise "it used to be implemented as Project"
        end

        # @since 1.1.0
        # @api private
        def requirements
          # FIXME: require components via the new Hanami::Container
          raise "it used to be implemented as Hanami::Components"
        end
      end
    end
  end
end
