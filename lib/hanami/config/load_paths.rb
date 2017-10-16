require 'hanami/utils'

module Hanami
  # @api private
  module Config
    # Define the load paths where the application should load
    #
    # @since 0.1.0
    # @api private
    class LoadPaths < Utils::LoadPaths
      # Overrides Utils::LoadPath initialize method
      #
      # @see Hanami::Utils::LoadPaths#initialize
      #
      # @since 0.1.0
      # @api private
      def initialize(root)
        super()
        @root = root
      end

      # Requires relative @pats [Utils::Kernel.Array] variable via each method
      #
      # @see Hanami::Utils::LoadPaths#each
      #
      # @since 0.1.0
      # @api private
      def load!
        each do |path|
          Utils.require!(path)
        end
      end

      protected

      # Overrides Utils::LoadPath realpath method
      #
      # @see Hanami::Utils::LoadPaths#realpath
      #
      # @api private
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
