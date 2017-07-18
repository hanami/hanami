module Hanami
  module Cli
    module Commands
      module Destroy
        class Migration < Command
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
            files.delete(context.path)
            say(:remove, context.path)
          end
        end
      end
    end
  end
end
