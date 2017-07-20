module Hanami
  class Cli
    module Commands
      module Generate
        class Model < Command
          requires "environment"
          argument :model, required: true
          option :skip_migration, type: :boolean, default: false

          def call(model:, **options)
            model     = Utils::String.new(model).underscore
            relation  = Utils::String.new(model).pluralize
            migration = "create_#{relation}"
            context   = Context.new(model: model, relation: relation, migration: migration, test: options.fetch(:test), options: options)

            generate_entity(context)
            generate_repository(context)
            generate_migration(context)
            generate_entity_spec(context)
            generate_repository_spec(context)
          end

          private

          def generate_entity(context)
            source      = templates.find("entity.erb")
            destination = project.entity(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_repository(context)
            source      = templates.find("repository.erb")
            destination = project.repository(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_migration(context)
            return if skip_migration?(context)

            source      = templates.find("migration.erb")
            destination = project.migration(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_entity_spec(context)
            source      = templates.find("entity_spec.#{context.test}.erb")
            destination = project.entity_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_repository_spec(context)
            source      = templates.find("repository_spec.#{context.test}.erb")
            destination = project.repository_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def skip_migration?(context)
            context.options.fetch(:skip_migration, false)
          end
        end
      end
    end
  end
end
