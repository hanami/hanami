module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Db
      class Console
        include Hanami::Cli::Command
        register "db console"

        def call(**options)
          context = Context.new(options: options)

          start_console(context)
        end

        private

        def start_console(context)
          # FIXME: this should be unified here
          require "hanami/commands/db/console"
          Commands::DB::Console.new({}, nil).start
        end
      end
    end
  end
end
