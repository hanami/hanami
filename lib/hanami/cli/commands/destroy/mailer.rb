module Hanami
  module Cli
    module Commands
      module Destroy
        class Mailer < Command
          requires "environment"
          argument :mailer, required: true

          def call(mailer:, **options)
            mailer  = Utils::String.new(mailer).underscore.singularize
            context = Context.new(mailer: mailer, options: options)

            assert_valid_mailer!(context)

            destroy_mailer_spec(context)
            destroy_templates(context)
            destroy_mailer(context)
          end

          private

          def assert_valid_mailer!(context)
            destination = project.mailer(context)
            return if files.exist?(destination)

            destination = project.mailers(context)
            warn "cannot find `#{context.mailer}' mailer. Please have a look at `#{destination}' directory to find an existing mailer."
            exit(1)
          end

          def destroy_mailer_spec(context)
            destination = project.mailer_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_templates(context)
            destinations = project.mailer_templates(context)
            destinations.each do |destination|
              files.delete(destination)
              say(:remove, destination)
            end
          end

          def destroy_mailer(context)
            destination = project.mailer(context)

            files.delete(destination)
            say(:remove, destination)
          end
        end
      end
    end
  end
end
