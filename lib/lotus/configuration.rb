require 'lotus/utils/kernel'
require 'lotus/config/loading_paths'
require 'lotus/config/routes'
require 'lotus/config/mapping'

module Lotus
  class Configuration
    DEFAULT_LOADING_PATH = 'app'.freeze

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
      @loading_paths ||= Config::LoadingPaths.new(root.join(DEFAULT_LOADING_PATH))
    end

    def routes(path = nil, &blk)
      if path or block_given?
        @routes = Config::Routes.new(path, &blk)
      else
        @routes
      end
    end

    def mapping(path = nil, &blk)
      if path or block_given?
        @mapping = Config::Mapping.new(path, &blk)
      else
        @mapping
      end
    end
  end
end
