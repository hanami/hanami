module Hanami
  module Cli
    module Commands
      module Generate
        class Migration < Command
          argument :migration, required: true

          def call(migration:, **options)
            # TODO: extract this operation into a mixin
            options = Hanami.environment.to_options.merge(options)

            migration = Utils::String.new(migration).underscore
            context   = Context.new(migration: migration, options: options)

            generate_migration(context)

            true
          end

          private

          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze

          FILENAME_PATTERN = '%{timestamp}_%{name}'.freeze

          def generate_migration(context)
            # FIXME: extract these hardcoded values
            timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
            filename  = FILENAME_PATTERN % { timestamp: timestamp, name: context.migration }

            destination = File.join("db", "migrations", "#{filename}.rb")
            source      = File.join(__dir__, "migration", "migration.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end
        end
      end
    end
  end
end
