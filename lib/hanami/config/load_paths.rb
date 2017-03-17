require 'hanami/utils'

module Hanami
  # @api private
  module Config
    # Define the load paths where the application should load
    #
    # @since 0.1.0
    # @api private
    class LoadPaths < Utils::LoadPaths
      # @api private
      def initialize(root)
        super()
        @root = root
      end

      # @api private
      def load!
        each do |path|
          Utils.require!(path)
        end
      end

      protected

      # @api private
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
