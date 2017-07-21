module Hanami
  class Cli
    module Commands
      module Db
        class Version < Command
          requires "model.configuration"

          desc "Print the current migrated version"

          def call(**options)
            context = Context.new(options: options)

            print_database_version(context)
          end

          private

          def print_database_version(context)
            require "hanami/model/migrator"
            puts Hanami::Model::Migrator.version
          end
        end
      end
    end
  end
end
