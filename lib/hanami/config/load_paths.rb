require 'hanami/utils/load_paths'

module Hanami
  module Config
    # Define the load paths where the application should load
    #
    # @since 0.1.0
    # @api private
    class LoadPaths < Utils::LoadPaths
      PATTERN = '**/*.rb'.freeze

      def load!(root)
        @root = root

        each do |path|
          Dir.glob(path.join(PATTERN)).sort.each { |file| require file }
        end
      end

      protected
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end

