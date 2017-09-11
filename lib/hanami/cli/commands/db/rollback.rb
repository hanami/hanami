module Hanami
  class CLI
    module Commands
      module Db
        # @since x.x.x
        # @api private
        class Rollback < Command
          requires "model.sql"

          desc "Rollback the database"

          argument :steps, desc: "Number of versions to rollback the database", default: 1

          example [
            "  # Rollback lastest version",
            "2 # Rollbacks two versions"
          ]

          # @since x.x.x
          # @api private
          def call(steps:, **options)
            context = Context.new(steps: steps.to_i)

            rollback_database(context)
          end

          private

          # @since x.x.x
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
