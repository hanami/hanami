module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Db
        class Drop
          include Hanami::Cli::Command
          register "db drop"

          def call(**options)
            context = Context.new(options: options)

            drop_database(context)
          end

          private

          def drop_database(context)
            # FIXME: this should be unified here
            require "hanami/commands/db/drop"
            Hanami::Commands::DB::Drop.new({}).start
          end
        end
      end
    end
  end
end
