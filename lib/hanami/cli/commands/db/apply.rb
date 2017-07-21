module Hanami
  class Cli
    module Commands
      module Db
        class Apply < Command
          requires "model.sql"

          desc "Migrate, dump the SQL schema, and delete the migrations (experimental)"

          def call(**options)
            context = Context.new(options: options)

            apply_migrations(context)
          end

          private

          def apply_migrations(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.apply
          end
        end
      end
    end
  end
end
