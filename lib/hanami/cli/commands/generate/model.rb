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
            model     = inflector.underscore(model)
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
            source      = templates.find("entity.erb")
            destination = project.entity(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_repository(context)
            source      = templates.find("repository.erb")
            destination = project.repository(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_migration(context)
            return if skip_migration?(context)

            source      = templates.find("migration.erb")
            destination = project.migration(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_entity_spec(context)
            source      = templates.find("entity_spec.#{context.test}.erb")
            destination = project.entity_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_repository_spec(context)
            source      = templates.find("repository_spec.#{context.test}.erb")
            destination = project.repository_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
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
              inflector.underscore(options[:relation])
            else
              inflector.pluralize(model)
            end
          end

          # @since 1.1.0
          # @api private
          def override_relation_name?(options)
            !options.fetch(:relation, nil).nil?
          end

          # @since x.x.x
          # @api private
          def inflector
            Hanami.configuration.inflector
          end
        end
      end
    end
  end
end
