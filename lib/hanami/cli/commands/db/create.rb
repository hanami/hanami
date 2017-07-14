module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Db
        class Create
          include Hanami::Cli::Command
          register "db create"

          def call(**options)
            context = Context.new(options: options)

            create_database(context)
          end

          private

          def create_database(context)
            # FIXME: this should be unified here
            require "hanami/commands/db/create"
            Hanami::Commands::DB::Create.new({}).start
          end
        end
      end
    end
  end
end
