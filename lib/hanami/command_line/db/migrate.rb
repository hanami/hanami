module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Db
      class Migrate
        include Hanami::Cli::Command
        register "db migrate"

        argument :version

        def call(version: nil, **options)
          context = Context.new(version: version, options: options)

          migrate_database(context)
        end

        private

        def migrate_database(context)
          # FIXME: this should be unified here
          require "hanami/commands/db/migrate"
          Commands::DB::Migrate.new({}, context.version).start
        end
      end
    end
  end
end
