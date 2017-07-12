module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Assets
      class Precompile
        include Hanami::Cli::Command
        register "assets precompile"

        def call(**options)
          context = Context.new(options: options)

          precompile_assets(context)
        end

        private

        def precompile_assets(context)
          # FIXME: this should be unified here
          require "hanami/commands/assets/precompile"
          Commands::Assets::Precompile.new({}).start
        end
      end
    end
  end
end
