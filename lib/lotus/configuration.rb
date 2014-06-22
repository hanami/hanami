require 'lotus/utils/kernel'
require 'lotus/config/load_paths'
require 'lotus/config/assets'
require 'lotus/config/routes'
require 'lotus/config/mapping'

module Lotus
  # Configuration for a Lotus application
  #
  # @since 0.1.0
  class Configuration
    # Initialize a new configuration instance
    #
    # @return [Lotus::Configuration]
    #
    # @since 0.1.0
    # @api private
    def initialize
      @blk = Proc.new{}
    end

    # Set a block yield when the configuration will be loaded
    #
    # @param blk [Proc] the configuration block
    #
    # @return [self]
    #
    # @since 0.1.0
    # @api private
    def configure(&blk)
      @blk = blk if block_given?
      self
    end

    # Load the configuration
    #
    # @param namespace [String,nil] the application namespace
    #
    # @return [self]
    #
    # @since 0.1.0
    # @api private
    def load!(namespace = nil)
      @namespace = namespace
      instance_eval(&@blk)
      self
    end

    # The root of the application
    #
    # By default it returns the current directory, for this reason, **all the
    # commands must be executed from the top level directory of the project**.
    #
    # If for some reason, that constraint above cannot be satisfied, please
    # configure the root directory, so that commands can be executed from
    # everywhere.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload root(value)
    #   Sets the given value
    #   @param value [String,Pathname,#to_pathname] The root directory of the app
    #
    # @overload root
    #   Gets the value
    #   @return [Pathname]
    #   @raise [Errno::ENOENT] if the path cannot be found
    #
    # @since 0.1.0
    #
    # @see http://www.ruby-doc.org/core-2.1.2/Dir.html#method-c-pwd
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.root # => #<Pathname:/path/to/root>
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         root '/path/to/another/root'
    #       end
    #     end
    #   end
    def root(value = nil)
      if value
        @root = value
      else
        Utils::Kernel.Pathname(@root || Dir.pwd).realpath
      end
    end

    def namespace(value = nil)
      if value
        @namespace = value
      else
        @namespace
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

    def assets(value = nil)
      if value
        @assets = value
      else
        Config::Assets.new(root, @assets)
      end
    end

    def load_paths
      @load_paths ||= Config::LoadPaths.new
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

    def default_format(format = nil)
      if format
        @default_format = Utils::Kernel.Symbol(format)
      else
        @default_format || :html
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

    def view_pattern(value = nil)
      if value
        @view_pattern = value
      else
        @view_pattern ||= 'Views::%{controller}::%{action}'
      end
    end
  end
end
