module Hanami
  class CLI
    module Commands
      module Generate
        # @since 1.1.0
        # @api private
        class Model < Command
          requires "environment"

          desc "Generate a model"

          argument :model, required: true, desc: "Model name (eg. `user`)"
          option :skip_migration, type: :boolean, default: false, desc: "Skip migration"
          option :relation, type: :string, desc: "Name of the database relation, default: pluralized model name"

          example [
            "user                     # Generate `User` entity, `UserRepository` repository, and the migration",
            "user --skip-migration    # Generate `User` entity and `UserRepository` repository",
            "user --relation=accounts # Generate `User` entity, `UserRepository` and migration to create `accounts` table"
          ]

          # @since 1.1.0
          # @api private
          def call(model:, **options)
            model     = Utils::String.underscore(model)
            relation  = relation_name(options, model)
            migration = "create_#{relation}"
            context   = Context.new(model: model, relation: relation, migration: migration, test: options.fetch(:test), override_relation_name: override_relation_name?(options), options: options)

            assert_valid_relation!(context)

            generate_entity(context)
            generate_repository(context)
            generate_migration(context)
            generate_entity_spec(context)
            generate_repository_spec(context)
          end

          private

          def assert_valid_relation!(context)
            if Utils::Blank.blank?(context.relation)
              warn "`#{context.relation}' is not a valid relation name"
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def generate_entity(context)
            destination = project.entity(context)

            generator.create("entity.erb", destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_repository(context)
            destination = project.repository(context)

            generator.create("repository.erb", destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_migration(context)
            return if skip_migration?(context)

            destination = project.migration(context)

            generator.create("migration.erb", destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_entity_spec(context)
            source      = "entity_spec.#{context.test}.erb"
            destination = project.entity_spec(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_repository_spec(context)
            source      = "repository_spec.#{context.test}.erb"
            destination = project.repository_spec(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def skip_migration?(context)
            context.options.fetch(:skip_migration, false)
          end

          # @since 1.1.0
          # @api private
          def relation_name(options, model)
            if override_relation_name?(options)
              Utils::String.underscore(options[:relation])
            else
              Utils::String.pluralize(model)
            end
          end

          # @since 1.1.0
          # @api private
          def override_relation_name?(options)
            !options.fetch(:relation, nil).nil?
          end
        end
      end
    end
  end
end
