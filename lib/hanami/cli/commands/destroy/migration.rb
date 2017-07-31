module Hanami
  class CLI
    module Commands
      module Destroy
        class Migration < Command
          desc "Destroy a migration"

          argument :migration, required: true, desc: "The migration name (eg. `create_users`)"

          example [
            "create_users # Destroy `db/migrations/#{Project.migration_timestamp}_create_users.rb`"
          ]

          def call(migration:, **options)
            migration   = Utils::String.new(migration).underscore
            context     = Context.new(migration: migration, options: options)
            context     = context.with(destination: project.find_migration(context))

            assert_valid_migration!(context)

            destroy_migration(context)
            true
          end

          private

          def assert_valid_migration!(context)
            return if !context.destination.nil? && files.exist?(context.destination)

            destination = project.migrations(context)
            warn "cannot find `#{context.migration}'. Please have a look at `#{destination}' directory to find an existing migration"
            exit(1)
          end

          def destroy_migration(context)
            files.delete(context.destination)
            say(:remove, context.destination)
          end
        end
      end
    end
  end
end
