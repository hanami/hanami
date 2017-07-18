module Hanami
  module Cli
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

            # FIXME this should be removed
            true
          end

          private

          def assert_valid_model!(context)
            # FIXME: extract these hardcoded values
            path = File.join("lib", context.options.fetch(:project), "entities", "#{context.model}.rb")
            return if File.exist?(path)

            path = File.join("lib", context.options.fetch(:project), "entities")
            warn "cannot find `#{context.model}' model. Please have a look at `#{path}' directory to find an existing model."
            exit(1)
          end

          def destroy_repository_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "repositories", "#{context.model}_repository_spec.rb")

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_entity_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "entities", "#{context.model}_spec.rb")

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_repository(context)
            destination = File.join("lib", context.options.fetch(:project), "repositories", "#{context.model}_repository.rb")

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_entity(context)
            destination = File.join("lib", context.options.fetch(:project), "entities", "#{context.model}.rb")

            files.delete(destination)
            say(:remove, destination)
          end
        end
      end
    end
  end
end
