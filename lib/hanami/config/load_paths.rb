require 'hanami/utils'

module Hanami
  # @api private
  module Config
    # Define the load paths where the application should load
    #
    # @since 0.1.0
    # @api private
    class LoadPaths < CygUtils::LoadPaths
      # Overrides CygUtils::LoadPath initialize method
      #
      # @see Hanami::CygUtils::LoadPaths#initialize
      #
      # @since 0.1.0
      # @api private
      def initialize(root)
        super()
        @root = root
      end

      # Requires relative @pats [CygUtils::Kernel.Array] variable via each method
      #
      # @see Hanami::CygUtils::LoadPaths#each
      #
      # @since 0.1.0
      # @api private
      def load!
        each do |path|
          Utils.require!(path)
        end
      end

      protected

      # Overrides CygUtils::LoadPath realpath method
      #
      # @see Hanami::CygUtils::LoadPaths#realpath
      #
      # @api private
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
