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
      # @see http://github.com/hanami/utils/blob/master/lib/hanami/utils/load_paths.rb#L20
      #
      # @since 0.1.0
      # @api private
      def initialize(root)
        super()
        @root = root
      end

      # Requires relative @pats [Utils::Kernel.Array] variable via each method
      #
      # @see http://github.com/hanami/utils/blob/master/lib/hanami/utils/load_paths.rb#L63
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
      # @see https://github.com/hanami/utils/blob/master/lib/hanami/utils/load_paths.rb#L164
      #
      # @api private
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
