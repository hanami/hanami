module Hanami
  module Cli
    module Commands
      module Db
        class Prepare < Command
          requires "model.sql"

          def call(**options)
            context = Context.new(options: options)

            prepare_database(context)
          end

          private

          def prepare_database(context)
            require 'hanami/model/migrator'
            Hanami::Model::Migrator.prepare
          end
        end
      end
    end
  end
end
