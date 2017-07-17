require "hanami/utils/blank"
require "securerandom"

module Hanami
  module Cli
    module Commands
      module Generate
        class Secret < Command
          argument :app

          def call(app: nil, **options)
            # TODO: extract this operation into a mixin
            options = Hanami.environment.to_options.merge(options)

            context = Context.new(app: app, options: options)

            generate_secret(context)

            true
          end

          private

          def generate_secret(context)
            if Hanami::Utils::Blank.blank?(context.app)
              puts SecureRandom.hex(32)
            else
              puts "Set the following environment variable to provide the secret token:"
              puts %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")
            end
          end
        end
      end
    end
  end
end
