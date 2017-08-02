module Hanami
  class CLI
    module Commands
      module Db
        class Console < Command
          requires 'model.sql'

          desc "Starts a database console"

          def call(**options)
            context = Context.new(options: options)

            start_console(context)
          end

          private

          def start_console(context)
            exec console.connection_string
          end

          def configuration_url
            Hanami::Components['model.configuration'].url
          end

          # @api private
          def console
            require "hanami/model/sql/console"
            Hanami::Model::Sql::Console.new(configuration_url)
          end
        end
      end
    end
  end
end
