module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Db
      class Prepare
        include Hanami::Cli::Command
        register "db prepare"

        def call(**options)
          context = Context.new(options: options)

          prepare_database(context)
        end

        private

        def prepare_database(context)
          # FIXME: this should be unified here
          require "hanami/commands/db/prepare"
          Commands::DB::Prepare.new({}).start
        end
      end
    end
  end
end
