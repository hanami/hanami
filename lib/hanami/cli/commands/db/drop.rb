module Hanami
  class CLI
    module Commands
      # @since x.x.x
      # @api private
      module Db
        class Drop < Command
          requires "model.configuration"

          desc "Drop the database (only for development/test)"

          # @since x.x.x
          # @api private
          def call(**options)
            context = Context.new(options: options)

            drop_database(context)
          end

          private

          # @since x.x.x
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
