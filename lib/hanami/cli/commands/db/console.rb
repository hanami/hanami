module Hanami
  class CLI
    module Commands
      module Db
        # @since 1.1.0
        # @api private
        class Console < Command
          requires 'model.sql'

          desc "Starts a database console"

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            start_console(context)
          end

          private

          # @since 1.1.0
          # @api private
          def start_console(*)
            exec console.connection_string
          end

          # @since 1.1.0
          # @api private
          def configuration_url
            Hanami::Components['model.configuration'].url
          end

          # @since 1.1.0
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
