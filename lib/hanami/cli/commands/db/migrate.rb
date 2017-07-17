module Hanami
  module Cli
    module Commands
      module Db
        class Migrate < Command
          requires "model.sql"
          argument :version

          def call(version: nil, **options)
            context = Context.new(version: version, options: options)

            migrate_database(context)
          end

          private

          def migrate_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.migrate(version: context.version)
          end
        end
      end
    end
  end
end
