module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Apply < Command
          requires "model.sql"

          desc "Migrate, dump the SQL schema, and delete the migrations (experimental)"

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            apply_migrations(context)
          end

          private

          # @since 1.1.0
          # @api private
          def apply_migrations(*)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.apply
          end
        end
      end
    end
  end
end
