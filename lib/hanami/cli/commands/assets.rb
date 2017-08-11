module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      module Assets
        require "hanami/cli/commands/assets/precompile"
      end
    end

    register "assets precompile", Commands::Assets::Precompile
  end
end
