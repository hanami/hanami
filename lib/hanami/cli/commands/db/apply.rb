module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Db
        class Apply
          include Hanami::Cli::Command
          register "db apply"

          def call(**options)
            context = Context.new(options: options)

            apply_migrations(context)
          end

          private

          def apply_migrations(context)
            # FIXME: this should be unified here
            require "hanami/commands/db/apply"
            Hanami::Commands::DB::Apply.new({}).start
          end
        end
      end
    end
  end
end
