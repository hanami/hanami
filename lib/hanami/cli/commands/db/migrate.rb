module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Migrate < Command
          requires "model.sql"

          desc "Migrate the database"

          argument :version, desc: "The target version of the migration (see `hanami db version`)"

          example [
            "               # Migrate to the last version",
            "#{Project.migration_timestamp} # Migrate to a specific version"
          ]

          # @since 1.1.0
          # @api private
          def call(version: nil, **options)
            context = Context.new(version: version, options: options)

            migrate_database(context)
          end

          private

          # @since 1.1.0
          # @api private
          def migrate_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.migrate(version: context.version)
          end
        end
      end
    end
  end
end
