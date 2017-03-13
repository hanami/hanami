module Hanami
  class CliSubCommands
    # A set of subcommands related to assets
    #
    # It is run with:
    #
    #   `bundle exec hanami assets`
    #
    # @since 0.6.0
    # @api private
    class Assets < Thor
      extend CliBase
      namespace :assets

      desc 'precompile', 'Precompile assets for deployment'
      # @since 0.6.0
      # @api private
      def precompile
        require 'hanami/commands/assets/precompile'
        Hanami::Commands::Assets::Precompile.new(options).start
      end
    end
  end
end
