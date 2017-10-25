module Hanami
  class CLI
    module Commands
      module Generate
        # @since 1.1.0
        # @api private
        class Migration < Command
          requires "environment"
          desc "Generate a migration"

          argument :migration, required: true, desc: "The migration name (eg. `create_users`)"

          example [
            "create_users # Generate `db/migrations/#{Project.migration_timestamp}_create_users.rb`"
          ]

          # @since 1.1.0
          # @api private
          def call(migration:, **options)
            migration = Utils::String.underscore(migration)
            context   = Context.new(migration: migration, options: options)

            generate_migration(context)
          end

          private

          # @since 1.1.0
          # @api private
          def generate_migration(context)
            source      = templates.find("migration.erb")
            destination = project.migration(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end
        end
      end
    end
  end
end
