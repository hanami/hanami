require 'lotus/utils/kernel'

module Lotus
  class Configuration
    def initialize(&blk)
      instance_eval(&blk) if block_given?
    end

    def root(value = nil)
      if value
        @root = Lotus::Utils::Kernel.Pathname(value).realpath
      else
        @root
      end
    end
  end
end
