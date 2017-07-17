module Hanami
  module Cli
    module Commands
      module Db
        class Apply < Command
          requires "model.sql"

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
