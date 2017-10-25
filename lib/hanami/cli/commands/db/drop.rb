module Hanami
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      module Db
        class Drop < Command
          requires "model.configuration"

          desc "Drop the database (only for development/test)"

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            drop_database(context)
          end

          private

          # @since 1.1.0
          # @api private
          def drop_database(*)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.drop
          end
        end
      end
    end
  end
end
