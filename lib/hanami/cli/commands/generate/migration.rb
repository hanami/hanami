module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Generate
        class Migration
          include Hanami::Cli::Command
          register "generate migration"

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
            template    = File.join(__dir__, "migration", "migration.erb")
            template    = File.read(template)

            renderer = Renderer.new
            output   = renderer.call(template, context.binding)

            FileUtils.mkpath(File.dirname(destination))
            File.open(destination, "wb") { |f| f.write(output) }

            say(:create, destination)
          end

          FORMATTER = "%<operation>12s  %<path>s\n".freeze

          def say(operation, path)
            puts(FORMATTER % { operation: operation, path: path })
          end
        end
      end
    end
  end
end
