require 'lotus/utils/load_paths'

module Lotus
  module Config
    # Define the load paths where the application should load
    #
    # #since 0.1.0
    # @api private
    class LoadPaths < Utils::LoadPaths
      PATTERN = '**/*.rb'.freeze

      def load!(root)
        each(root) do |path|
          Dir.glob(path.join(PATTERN)).each {|file| require file }
        end
      end

      protected
      def each(root, &blk)
        # FIXME implement #realpath in Utils::LoadPaths
        Utils::Kernel.Array(@paths).each do |path|
          blk.call root.join(path).realpath
        end
      end
    end
  end
end

