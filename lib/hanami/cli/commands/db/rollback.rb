require "hanami/utils/kernel"

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
            context = Context.new(steps: steps)
            context = assert_valid_steps!(context)

            rollback_database(context)
          end

          private

          # @since 1.1.0
          # @api private
          def assert_valid_steps!(context)
            context = context.with(steps: Utils::Kernel.Integer(context.steps.to_s))
            handle_error(context) unless context.steps.positive?
            context
          rescue TypeError
            handle_error(context)
          end

          # @since 1.1.0
          # @api private
          def rollback_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.rollback(steps: context.steps)
          end

          # @since 1.1.0
          # @api private
          def handle_error(context)
            warn "the number of steps must be a positive integer (you entered `#{context.steps}')."
            exit(1)
          end
        end
      end
    end
  end
end
