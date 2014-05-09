require 'lotus/utils/kernel'
require 'lotus/config/loading_paths'

module Lotus
  class Configuration
    def initialize(&blk)
      instance_eval(&blk) if block_given?
    end

    def root(value = nil)
      if value
        @root = Utils::Kernel.Pathname(value).realpath
      else
        @root
      end
    end

    def loading_paths
      @loading_paths ||= Config::LoadingPaths.new(root)
    end
  end
end
