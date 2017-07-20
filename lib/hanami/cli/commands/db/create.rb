module Hanami
  class Cli
    module Commands
      module Db
        class Create < Command
          requires "model.configuration"

          def call(**options)
            context = Context.new(options: options)

            create_database(context)
          end

          private

          def create_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.create
          end
        end
      end
    end
  end
end
