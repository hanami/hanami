module Hanami
  class CLI
    module Commands
      module Destroy
        # @since 1.1.0
        # @api private
        class Mailer < Command
          requires "environment"
          desc "Destroy a mailer"

          argument :mailer, required: true, desc: "The mailer name (eg. `welcome`)"

          example [
            "welcome # Destroy `WelcomeMailer` mailer"
          ]

          # @since 1.1.0
          # @api private
          def call(mailer:, **options)
            mailer  = inflector.singularize(inflector.underscore(mailer))
            context = Context.new(mailer: mailer, options: options)

            assert_valid_mailer!(context)

            destroy_mailer_spec(context)
            destroy_templates(context)
            destroy_mailer(context)
          end

          private

          # @since 1.1.0
          # @api private
          def assert_valid_mailer!(context)
            destination = project.mailer(context)
            return if files.exist?(destination)

            destination = project.mailers(context)
            warn "cannot find `#{context.mailer}' mailer. Please have a look at `#{destination}' directory to find an existing mailer."
            exit(1)
          end

          # @since 1.1.0
          # @api private
          def destroy_mailer_spec(context)
            destination = project.mailer_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          # @since 1.1.0
          # @api private
          def destroy_templates(context)
            destinations = project.mailer_templates(context)
            destinations.each do |destination|
              files.delete(destination)
              say(:remove, destination)
            end
          end

          # @since 1.1.0
          # @api private
          def destroy_mailer(context)
            destination = project.mailer(context)

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
