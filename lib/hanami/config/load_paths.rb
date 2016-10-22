require 'hanami/utils'

module Hanami
  module Config
    # Define the load paths where the application should load
    #
    # @since 0.1.0
    # @api private
    class LoadPaths < Utils::LoadPaths
      def initialize(root)
        super()
        @root = root
      end

      def load!
        each do |path|
          Utils.require!(path)
        end
      end

      protected

      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
