module Hanami
  module Cli
    module Commands
      module Generate
        class Model < Command
          requires "environment"
          argument :model, required: true
          option :skip_migration, type: :boolean, default: false

          def call(model:, **options)
            model    = Utils::String.new(model).underscore
            relation = Utils::String.new(model).pluralize
            context  = Context.new(model: model, relation: relation, test: options.fetch(:test), options: options)

            generate_entity(context)
            generate_repository(context)
            generate_migration(context)
            generate_entity_spec(context)
            generate_repository_spec(context)

            true
          end

          private

          def generate_entity(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "entities", "#{context.model}.rb")
            source      = File.join(__dir__, "model", "entity.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_repository(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "repositories", "#{context.model}_repository.rb")
            source      = File.join(__dir__, "model", "repository.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze

          FILENAME_PATTERN = '%{timestamp}_%{name}'.freeze

          # FIXME: This is a logic duplication on Generate::Migration#generate_migration
          def generate_migration(context)
            return if context.options.fetch(:skip_migration, false)

            # FIXME: extract these hardcoded values
            timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
            filename  = FILENAME_PATTERN % { timestamp: timestamp, name: "create_#{context.relation}" }

            destination = File.join("db", "migrations", "#{filename}.rb")
            source      = File.join(__dir__, "model", "migration.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_entity_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "entities", "#{context.model}_spec.rb")
            source      = File.join(__dir__, "model", "entity_spec.#{context.test}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_repository_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "repositories", "#{context.model}_repository_spec.rb")
            source      = File.join(__dir__, "model", "repository_spec.#{context.test}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end
        end
      end
    end
  end
end