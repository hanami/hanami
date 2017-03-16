require 'hanami/assets'
require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class Assets
      # @api private
      class Precompile < Command
        requires 'apps.assets.configurations'

        # @api private
        def start
          Hanami::Assets.precompile(configurations)
        end

        private

        # @api private
        def configurations
          requirements['apps.assets.configurations']
        end
      end
    end
  end
end
