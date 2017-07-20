module Hanami
  class Cli
    module Commands
      module Assets
        class Precompile < Command
          requires "apps.assets.configurations"

          desc "Precompile assets for deployment"
          def call(**options)
            context = Context.new(options: options)

            precompile_assets(context)
          end

          private

          def precompile_assets(context)
            Hanami::Assets.precompile(configurations)
          end

          # @api private
          def configurations
            requirements['apps.assets.configurations']
          end
        end
      end
    end
  end
end
