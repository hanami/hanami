require "hanami/utils/blank"
require "securerandom"

module Hanami
  class CLI
    module Commands
      module Generate
        # @since 1.1.0
        # @api private
        class Secret < Command
          requires "environment"

          desc "Generate session secret"

          argument :app, desc: "The application name (eg. `web`)"

          example [
            "    # Prints secret (eg. `#{Project.app_sessions_secret}`)",
            "web # Prints session secret (eg. `WEB_SESSIONS_SECRET=#{Project.app_sessions_secret}`)"
          ]

          # @since 1.1.0
          # @api private
          def call(app: nil, **options)
            context = Context.new(app: app, options: options)

            generate_secret(context)
          end

          private

          # @since 1.1.0
          # @api private
          def generate_secret(context)
            secret = project.app_sessions_secret

            if Hanami::Utils::Blank.blank?(context.app)
              puts secret
            else
              puts "Set the following environment variable to provide the secret token:"
              puts %(#{context.app.upcase}_SESSIONS_SECRET="#{secret}")
            end
          end
        end
      end
    end
  end
end
