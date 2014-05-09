require 'lotus/utils/kernel'

module Lotus
  module Config
    class LoadingPaths < Array
      def initialize(*paths)
        super(Array(paths))
      end

      def each(&blk)
        Utils::Kernel.Array(self).each do |path|
          blk.call Utils::Kernel.Pathname(path).realpath
        end
      end
    end
  end
end

