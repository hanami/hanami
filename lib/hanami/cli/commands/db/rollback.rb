module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Rollback < Command
          requires "model.sql"

          desc "Rollback migrations"

          argument :steps, desc: "Number of steps to rollback the database", default: 1

          example [
            "  # Rollbacks latest migration",
            "2 # Rollbacks last two migrations"
          ]

          # @since 1.1.0
          # @api private
          def call(steps:, **)
            context = Context.new(steps: steps.to_int)

            rollback_database(context)
          end

          private

          # @since 1.1.0
          # @api private
          def rollback_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.rollback(steps: context.steps)
          end
        end
      end
    end
  end
end
