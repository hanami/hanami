require 'hanami/assets'
require 'hanami/commands/command'

module Hanami
  module Commands
    class Assets
      class Precompile < Command
        requires 'apps.assets.configurations'

        def start
      require 'byebug'
      byebug
          Hanami::Assets.precompile(configurations)
        end

        private

        def configurations
          requirements['apps.assets.configurations']
        end
      end
    end
  end
end
