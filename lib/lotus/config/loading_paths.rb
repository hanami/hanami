require 'lotus/utils/kernel'

module Lotus
  module Config
    class LoadingPaths < Array
      PATTERN = '**/*.rb'.freeze

      def initialize(*paths)
        super(Array(paths))
      end

      def each(&blk)
        Utils::Kernel.Array(self).each do |path|
          blk.call Utils::Kernel.Pathname(path).realpath
        end
      end

      def load!
        each do |path|
          Dir.glob(path.join(PATTERN)).each {|file| require file }
        end
      end
    end
  end
end

