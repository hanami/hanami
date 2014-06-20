require 'lotus/utils/kernel'
require 'lotus/config/load_paths'
require 'lotus/config/routes'
require 'lotus/config/mapping'

module Lotus
  class Configuration
    DEFAULT_LOAD_PATH = 'app'.freeze

    def initialize(&blk)
      @blk = blk || Proc.new{}
    end

    # @api private
    def load!
      instance_eval(&@blk)
      self
    end

    def root(value = nil)
      if value
        @root = value
      else
        Utils::Kernel.Pathname(@root || Dir.pwd).realpath
      end
    end

    def layout(value = nil)
      if value
        @layout = value
      else
        @layout
      end
    end

    def templates(value = nil)
      if value
        @templates = value
      else
        root.join @templates.to_s
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

    def scheme(value = nil)
      if value
        @scheme = value
      else
        @scheme ||= 'http'
      end
    end

    def host(value = nil)
      if value
        @host = value
      else
        @host ||= 'localhost'
      end
    end

    def port(value = nil)
      if value
        @port = Integer(value)
      else
        @port ||
          case scheme
          when 'http'  then 80
          when 'https' then 443
          end
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
