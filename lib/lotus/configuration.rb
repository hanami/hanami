require 'lotus/utils/kernel'
require 'lotus/config/load_paths'
require 'lotus/config/routes'
require 'lotus/config/mapping'

module Lotus
  class Configuration
    DEFAULT_LOAD_PATH = 'app'.freeze

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

    def layout(value = nil)
      if value
        @layout = value
      else
        @layout
      end
    end

    def load_paths
      @load_paths ||= Config::LoadPaths.new(root.join(DEFAULT_LOAD_PATH))
    end

    def routes(path = nil, &blk)
      if path or block_given?
        @routes = Config::Routes.new(root, path, &blk)
      else
        @routes
      end
    end

    def mapping(path = nil, &blk)
      if path or block_given?
        @mapping = Config::Mapping.new(root, path, &blk)
      else
        @mapping
      end
    end

    def controller_pattern(value = nil)
      if value
        @controller_pattern = value
      else
        @controller_pattern ||= 'Controllers::%{controller}::%{action}'
      end
    end
  end
end
