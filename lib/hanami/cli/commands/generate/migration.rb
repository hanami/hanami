module Hanami
  module Cli
    module Commands
      module Generate
        class Migration < Command
          requires "environment"
          argument :migration, required: true

          def call(migration:, **options)
            migration = Utils::String.new(migration).underscore
            context   = Context.new(migration: migration, options: options)

            generate_migration(context)
          end

          private

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
