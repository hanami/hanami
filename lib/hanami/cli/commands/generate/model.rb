module Hanami
  module Cli
    module Commands
      module Generate
        class Model < Command
          argument :model, required: true
          option :skip_migration, type: :boolean, default: false

          def call(model:, **options)
            # TODO: extract this operation into a mixin
            options = Hanami.environment.to_options.merge(options)

            model    = Utils::String.new(model).underscore
            relation = Utils::String.new(model).pluralize
            context  = Context.new(model: model, relation: relation, test: options.fetch(:test), options: options)

            generate_entity(context)
            generate_repository(context)
            generate_migration(context)
            generate_entity_spec(context)
            generate_repository_spec(context)

            true
          end

          private

          def generate_entity(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "entities", "#{context.model}.rb")
            template    = File.join(__dir__, "model", "entity.erb")
            template    = File.read(template)

            renderer = Renderer.new
            output   = renderer.call(template, context.binding)

            FileUtils.mkpath(File.dirname(destination))
            File.open(destination, "wb") { |f| f.write(output) }

            say(:create, destination)
          end

          def generate_repository(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "repositories", "#{context.model}_repository.rb")
            template    = File.join(__dir__, "model", "repository.erb")
            template    = File.read(template)

            renderer = Renderer.new
            output   = renderer.call(template, context.binding)

            FileUtils.mkpath(File.dirname(destination))
            File.open(destination, "wb") { |f| f.write(output) }

            say(:create, destination)
          end

          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze

          FILENAME_PATTERN = '%{timestamp}_%{name}'.freeze

          # FIXME: This is a logic duplication on Generate::Migration#generate_migration
          def generate_migration(context)
            return if context.options.fetch(:skip_migration, false)

            # FIXME: extract these hardcoded values
            timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
            filename  = FILENAME_PATTERN % { timestamp: timestamp, name: "create_#{context.relation}" }

            destination = File.join("db", "migrations", "#{filename}.rb")
            template    = File.join(__dir__, "model", "migration.erb")
            template    = File.read(template)

            renderer = Renderer.new
            output   = renderer.call(template, context.binding)

            FileUtils.mkpath(File.dirname(destination))
            File.open(destination, "wb") { |f| f.write(output) }

            say(:create, destination)
          end

          def generate_entity_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "entities", "#{context.model}_spec.rb")
            template    = File.join(__dir__, "model", "entity_spec.#{context.test}.erb")
            template    = File.read(template)

            renderer = Renderer.new
            output   = renderer.call(template, context.binding)

            FileUtils.mkpath(File.dirname(destination))
            File.open(destination, "wb") { |f| f.write(output) }

            say(:create, destination)
          end

          def generate_repository_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "repositories", "#{context.model}_repository_spec.rb")
            template    = File.join(__dir__, "model", "repository_spec.#{context.test}.erb")
            template    = File.read(template)

            renderer = Renderer.new
            output   = renderer.call(template, context.binding)

            FileUtils.mkpath(File.dirname(destination))
            File.open(destination, "wb") { |f| f.write(output) }

            say(:create, destination)
          end

          FORMATTER = "%<operation>12s  %<path>s\n".freeze

          def say(operation, path)
            puts(FORMATTER % { operation: operation, path: path })
          end
        end
      end
    end
  end
end
