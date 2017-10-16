module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Create < Command
          requires "model.configuration"

          desc "Create the database (only for development/test)"

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            create_database(context)
          end

          private

          # @since 1.1.0
          # @api private
          def create_database(*)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.create
          end
        end
      end
    end
  end
end
