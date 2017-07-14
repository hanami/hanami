module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Db
        class Version
          include Hanami::Cli::Command
          register "db version"

          def call(**options)
            context = Context.new(options: options)

            print_database_version(context)
          end

          private

          def print_database_version(context)
            # FIXME: this should be unified here
            require "hanami/commands/db/version"
            Hanami::Commands::DB::Version.new({}).start
          end
        end
      end
    end
  end
end
