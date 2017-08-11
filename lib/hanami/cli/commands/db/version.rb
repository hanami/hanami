module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Version < Command
          requires "model.configuration.no_logger"

          desc "Print the current migrated version"

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            print_database_version(context)
          end

          private

          # @since 1.1.0
          # @api private
          def print_database_version(*)
            require "hanami/model/migrator"
            puts Hanami::Model::Migrator.version
          end
        end
      end
    end
  end
end
