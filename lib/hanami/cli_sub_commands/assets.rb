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
      namespace :assets

      desc 'precompile', 'Precompile assets for deployment'
      def precompile
        require 'hanami/commands/assets/precompile'
        Hanami::Commands::Assets::Precompile.new(options, environment).start
      end

      private

      # @since 0.6.0
      # @api private
      def environment
        Hanami::Environment.new(options)
      end
    end
  end
end
