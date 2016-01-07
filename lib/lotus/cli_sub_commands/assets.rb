module Lotus
  class CliSubCommands
    # A set of subcommands related to assets
    #
    # It is run with:
    #
    #   `bundle exec lotus assets`
    #
    # @since 0.6.0
    # @api private
    class Assets < Thor
      namespace :assets

      desc 'precompile', 'precompile assets for deployment'
      def precompile
        require 'lotus/commands/assets/precompile'
        Lotus::Commands::Assets::Precompile.new(options, environment).start
      end

      private

      # @since 0.6.0
      # @api private
      def environment
        Lotus::Environment.new(options)
      end
    end
  end
end
