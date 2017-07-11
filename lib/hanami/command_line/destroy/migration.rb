module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Destroy
      class Migration
        include Hanami::Cli::Command
        register "destroy migration"

        argument :migration, required: true

        def call(migration:, **options)
          # TODO: extract this operation into a mixin
          options = Hanami.environment.to_options.merge(options)

          migration = Utils::String.new(migration).underscore
          path      = find_migration(migration)
          context   = Context.new(migration: migration, path: path, options: options)

          assert_valid_migration!(context)

          destroy_migration(context)

          # FIXME this should be removed
          true
        end

        private

        def assert_valid_migration!(context)
          return unless context.path.nil?
          # FIXME: extract these hardcoded values
          path = File.join("db", "migrations")
          warn "cannot find `#{context.migration}'. Please have a look at `#{path}' directory to find an existing migration"
          exit(1)
        end

        def find_migration(migration)
          # FIXME: extract these hardcoded values
          Dir.glob(File.join("db", "migrations", "*_#{migration}.rb")).first
        end

        def destroy_migration(context)
          FileUtils.rm(context.path)

          say(:remove, context.path)
        end

        FORMATTER = "%<operation>12s  %<path>s\n".freeze

        def say(operation, path)
          puts(FORMATTER % { operation: operation, path: path })
        end
      end
    end
  end
end
