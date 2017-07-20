module Hanami
  class Cli
    module Commands
      module Destroy
        class Model < Command
          requires "environment"
          argument :model, required: true

          def call(model:, **options)
            model   = Utils::String.new(model).underscore.singularize
            context = Context.new(model: model, options: options)

            assert_valid_model!(context)

            destroy_repository_spec(context)
            destroy_entity_spec(context)
            destroy_repository(context)
            destroy_entity(context)
          end

          private

          def assert_valid_model!(context)
            destination = project.entity(context)
            return if files.exist?(destination)

            destination = project.entities(context)
            warn "cannot find `#{context.model}' model. Please have a look at `#{destination}' directory to find an existing model."
            exit(1)
          end

          def destroy_repository_spec(context)
            destination = project.repository_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_entity_spec(context)
            destination = project.entity_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_repository(context)
            destination = project.repository(context)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_entity(context)
            destination = project.entity(context)

            files.delete(destination)
            say(:remove, destination)
          end
        end
      end
    end
  end
end
