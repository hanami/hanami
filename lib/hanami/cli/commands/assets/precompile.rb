module Hanami
  class CLI
    module Commands
      module Assets
        # @since 1.1.0
        # @api private
        class Precompile < Command
          requires "apps.assets.configurations"

          desc "Precompile assets for deployment"

          example [
            "                      # Basic usage",
            "HANAMI_ENV=production # Precompile assets for production environment"
          ]

          # @since 1.1.0
          # @api private
          def call(**options)
            context = Context.new(options: options)

            precompile_assets(context)
          end

          private

          # @since 1.1.0
          # @api private
          def precompile_assets(*)
            Hanami::Assets.precompile(configurations)
          end

          # @since 1.1.0
          # @api private
          def configurations
            requirements['apps.assets.configurations']
          end
        end
      end
    end
  end
end
