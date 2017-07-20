module Hanami
  class Cli
    module Commands
      module Db
        class Drop < Command
          requires "model.configuration"

          def call(**options)
            context = Context.new(options: options)

            drop_database(context)
          end

          private

          def drop_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.drop
          end
        end
      end
    end
  end
end
