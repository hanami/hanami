module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Prepare < Command
          requires "model.sql"

          desc "Drop, create, and migrate the database (only for development/test)"

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            prepare_database(context)
          end

          private

          # @since 1.1.0
          # @api private
          def prepare_database(*)
            require 'hanami/model/migrator'
            Hanami::Model::Migrator.prepare
          end
        end
      end
    end
  end
end
