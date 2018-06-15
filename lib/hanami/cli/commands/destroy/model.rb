module Hanami
  class CLI
    module Commands
      module Destroy
        # @since 1.1.0
        # @api private
        class Model < Command
          requires "environment"

          desc "Destroy a model"

          argument :model, required: true, desc: "The model name (eg. `user`)"

          example [
            "user # Destroy `User` entity and `UserRepository` repository"
          ]

          # @since 1.1.0
          # @api private
          def call(model:, **options)
            model   = inflector.singularize(inflector.underscore(model))
            context = Context.new(model: model, options: options)

            assert_valid_model!(context)

            destroy_repository_spec(context)
            destroy_entity_spec(context)
            destroy_repository(context)
            destroy_entity(context)
          end

          private

          # @since 1.1.0
          # @api private
          def assert_valid_model!(context)
            destination = project.entity(context)
            return if files.exist?(destination)

            destination = project.entities(context)
            warn "cannot find `#{context.model}' model. Please have a look at `#{destination}' directory to find an existing model."
            exit(1)
          end

          # @since 1.1.0
          # @api private
          def destroy_repository_spec(context)
            destination = project.repository_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          # @since 1.1.0
          # @api private
          def destroy_entity_spec(context)
            destination = project.entity_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          # @since 1.1.0
          # @api private
          def destroy_repository(context)
            destination = project.repository(context)

            files.delete(destination)
            say(:remove, destination)
          end

          # @since 1.1.0
          # @api private
          def destroy_entity(context)
            destination = project.entity(context)

            files.delete(destination)
            say(:remove, destination)
          end

          # @since x.x.x
          # @api private
          def inflector
            Hanami.configuration.inflector
          end
        end
      end
    end
  end
end
