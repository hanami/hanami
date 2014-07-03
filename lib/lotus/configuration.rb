require 'lotus/utils/kernel'
require 'lotus/environment'
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
      @env = Environment.new
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

    # The application namespace
    #
    # By default it returns the Ruby namespace of the application. For instance
    # for an application `Bookshelf::Application`, it returns `Bookshelf`.
    #
    # This value isn't set at the init time, but when the configuration is
    # loaded with `#load!`.
    #
    # Lotus applications are namespaced: all the controllers and views live
    # under the application module, without polluting the global namespace.
    # However, if for some reason, you want top level classes, set this value
    # to `Object` (which is the top level namespace for Ruby).
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload namespace(value)
    #   Sets the given value
    #   @param value [Class,Module] A valid Ruby namespace
    #
    # @overload namespace
    #   Gets the value
    #   @return [Class,Module] a Ruby namespace
    #
    # @since 0.1.0
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.namespace # => Bookshelf
    #
    #   # It will lookup namespaced controllers under Bookshelf
    #   # eg. Bookshelf::Controllers::Dashboard
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         namespace Object
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.namespace # => Object
    #
    #   # It will lookup top level controllers under Object
    #   # eg. DashboardController
    def namespace(value = nil)
      if value
        @namespace = value
      else
        @namespace
      end
    end

    # A Lotus::Layout for this application
    #
    # By default it's `nil`.
    #
    # It accepts a Symbol as layout name. When the application is loaded, it
    # will lookup for the corresponding class.
    #
    # All the views will use this layout, unless otherwise specified.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload layout(value)
    #   Sets the given value
    #   @param value [Symbol] the layout name
    #
    # @overload layout
    #   Gets the value
    #   @return [Symbol,nil] the layout name
    #
    # @since 0.1.0
    #
    # @see http://rdoc.info/gems/lotus-view/Lotus/Layout
    # @see http://rdoc.info/gems/lotus-view/Lotus/View/Configuration:layout
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.layout # => nil
    #
    #   # All the views will render without a layout
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         layout :application
    #       end
    #     end
    #
    #     module Views
    #       module Dashboard
    #         class Index
    #           include Bookshelf::Views
    #         end
    #
    #         class JsonIndex < Index
    #           layout nil
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.namespace layout => :application
    #
    #   # All the views will use Bookshelf::Views::ApplicationLayout, unless
    #   # they set a different value.
    #
    #   Bookshelf::Views::Dashboard::Index.layout
    #     # => Bookshelf::Views::ApplicationLayout
    #
    #   Bookshelf::Views::Dashboard::JsonIndex.layout
    #     # => Lotus::View::Rendering::NullLayout
    def layout(value = nil)
      if value
        @layout = value
      else
        @layout
      end
    end

    # Templates root.
    # The application will recursively look for templates under this path.
    #
    # By default it's equal to the application `root`.
    #
    # Otherwise, you can specify a different relative path under `root`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload templates(value)
    #   Sets the given value
    #   @param value [String] the relative path to the templates root.
    #
    # @overload templates
    #   Gets the value
    #   @return [Pathname] templates root
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration#root
    # @see http://rdoc.info/gems/lotus-view/Lotus/View/Configuration:root
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.templates
    #     # => #<Pathname:/root/path>
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         templates 'app/templates'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.templates
    #     # => #<Pathname:/root/path/app/templates>
    def templates(value = nil)
      if value
        @templates = value
      else
        root.join @templates.to_s
      end
    end

    # Assets root.
    # The application will serve the static assets under this directory.
    #
    # By default it's equal to the `public/` directory under the application
    # `root`.
    #
    # Otherwise, you can specify a different relative path under `root`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload assets(value)
    #   Sets the given value
    #   @param value [String] the relative path to the assets dir.
    #
    # @overload assets
    #   Gets the value
    #   @return [Lotus::Config::Assets] assets root
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration#root
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.assets
    #     # => #<Pathname:/root/path/public>
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         assets 'assets'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.assets
    #     # => #<Pathname:/root/path/assets>
    def assets(value = nil)
      if value
        @assets = value
      else
        Config::Assets.new(root, @assets)
      end
    end

    # Application load paths
    # The application will recursively load all the Ruby files under these paths.
    #
    # By default it's empty in order to allow developers to decide their own
    # app structure.
    #
    # @return [Lotus::Config::LoadPaths] a set of load paths
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration#root
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.load_paths
    #     # => #<Lotus::Config::LoadPaths:0x007ff4fa212310 @paths=[]>
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         load_paths << [
    #           'app/controllers',
    #           'app/views
    #         ]
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.assets
    #     # => #<Lotus::Config::LoadPaths:0x007fe3a20b18e0 @paths=[["app/controllers", "app/views"]]>
    def load_paths
      @load_paths ||= Config::LoadPaths.new
    end

    # Application routes.
    #
    # Specify a set of routes for the application, by passing a block, or a
    # relative path where to find the file that describes them.
    #
    # By default it's `nil`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload routes(blk)
    #   Specify a set of routes in the given block
    #   @param blk [Proc] the routes definitions
    #
    # @overload routes(path)
    #   Specify a relative path where to find the routes file
    #   @param path [String] the relative path
    #
    # @overload routes
    #   Gets the value
    #   @return [Lotus::Config::Routes] the set of routes
    #
    # @since 0.1.0
    #
    # @see http://rdoc.info/gems/lotus-router/Lotus/Router
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.routes
    #     # => nil
    #
    # @example Setting the value, by passing a block
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         routes do
    #           get '/', to: 'dashboard#index'
    #           resources :books
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.routes
    #     # => #<Lotus::Config::Routes:0x007ff50a991388 @blk=#<Proc:0x007ff50a991338@(irb):4>, @path=#<Pathname:.>>
    #
    # @example Setting the value, by passing a relative path
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         routes 'config/routes'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.routes
    #     # => #<Lotus::Config::Routes:0x007ff50a991388 @blk=nil, @path=#<Pathname:config/routes.rb>>
    def routes(path = nil, &blk)
      if path or block_given?
        @routes = Config::Routes.new(root, path, &blk)
      else
        @routes
      end
    end

    # since 0.1.0
    # @api private
    def mapping(path = nil, &blk)
      if path or block_given?
        @mapping = Config::Mapping.new(root, path, &blk)
      else
        @mapping
      end
    end

    # Set a format as default fallback for all the requests without a strict
    # requirement for the mime type.
    #
    # The given format must be coercible to a symbol, and be a valid mime type
    # alias. If it isn't, at the runtime the framework will raise a 
    # `Lotus::Controller::UnknownFormatError`.
    #
    # By default this value is `:html`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload default_format(format)
    #   Sets the given value
    #   @param format [#to_sym] the symbol format
    #   @raise [TypeError] if it cannot be coerced to a symbol
    #
    # @overload default_format
    #   Gets the value
    #   @return [Symbol]
    #
    # @since 0.1.0
    #
    # @see http://rdoc.info/gems/lotus-controller/Lotus/Controller/Configuration#default_format
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.default_format # => :html
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         default_format :json
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.default_format # => :json
    def default_format(format = nil)
      if format
        @default_format = Utils::Kernel.Symbol(format)
      else
        @default_format || :html
      end
    end

    # The URI scheme for this application.
    # This is used by the router helpers to generate absolute URLs.
    #
    # By default this value is `"http"`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload scheme(value)
    #   Sets the given value
    #   @param value [String] the URI scheme
    #
    # @overload scheme
    #   Gets the value
    #   @return [String]
    #
    # @since 0.1.0
    #
    # @see http://en.wikipedia.org/wiki/URI_scheme
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.scheme # => "http"
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         scheme 'https'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.scheme # => "https"
    def scheme(value = nil)
      if value
        @scheme = value
      else
        @scheme ||= 'http'
      end
    end

    # The URI host for this application.
    # This is used by the router helpers to generate absolute URLs.
    #
    # By default this value is `"localhost"`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload host(value)
    #   Sets the given value
    #   @param value [String] the URI host
    #
    # @overload scheme
    #   Gets the value
    #   @return [String]
    #
    # @since 0.1.0
    #
    # @see http://en.wikipedia.org/wiki/URI_scheme
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.host # => "localhost"
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         host 'bookshelf.org'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.host # => "bookshelf.org"
    def host(value = nil)
      if value
        @host = value
      else
        @host ||= @env.host
      end
    end

    # The URI port for this application.
    # This is used by the router helpers to generate absolute URLs.
    #
    # By default this value is `80`, if `scheme` is `"http"`, or `443` if
    # `scheme` is `"https"`.
    #
    # This is optional, you should set this value only if your application
    # listens on a port not listed above.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload port(value)
    #   Sets the given value
    #   @param value [#to_int] the URI port
    #   @raise [TypeError] if the given value cannot be coerced to Integer
    #
    # @overload scheme
    #   Gets the value
    #   @return [String]
    #
    # @since 0.1.0
    #
    # @see http://en.wikipedia.org/wiki/URI_scheme
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.port # => 80
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         port 2323
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.port # => 2323
    def port(value = nil)
      if value
        @port = Integer(value)
      else
        # FIXME this hack MUST be removed when we implement the multi-environment feature
        #
        # when @port is set:
        #   it always takes the precedence
        # when @port isn't set:
        #   development:
        #     @env.port should take the precedence
        #   other env:
        #     the scheme should take the precedence
        @port || ((@env.port != 2300) ? @env.port : nil) ||
          case scheme
          when 'http'  then 80
          when 'https' then 443
          end
      end
    end

    # Defines a relative pattern to find controllers.
    #
    # Lotus supports multiple architectures (aka application structures), this
    # setting helps to understand the namespace where to find applications'
    # controllers and actions.
    #
    # By default this equals to `"Controllers::%{controller}::%{action}"`
    # That means controllers must be structured like this:
    # `Bookshelf::Controllers::Dashboard::Index`, where `Bookshelf` is the
    # application module, `Controllers` is the first value specified in the
    # pattern, `Dashboard` the controller and `Index` the action.
    #
    # This pattern MUST always contain `"%{controller}"` and `%{action}`.
    # This pattern SHOULD be used accordingly to `#view_pattern` value.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload controller_pattern(value)
    #   Sets the given value
    #   @param value [String] the controller pattern
    #
    # @overload controller_pattern
    #   Gets the value
    #   @return [String]
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration#view_pattern
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #
    #     module Controllers
    #       module Dashboard
    #         include Bookshelf::Controller
    #
    #         action 'Index' do
    #           def call(params)
    #             # ...
    #           end
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.controller_pattern
    #     # => "Controllers::%{controller}::%{action}"
    #
    #   # All the controllers MUST live under Bookshelf::Controllers
    #
    #   # GET '/' # => Bookshelf::Controllers::Dashboard::Index
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         controller_pattern "%{controller}Controller::%{action}"
    #
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #
    #     module DashboardController
    #       include Bookshelf::Controller
    #
    #       action 'Index' do
    #         def call(params)
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.controller_pattern
    #     # => "%{controller}Controller::%{action}"
    #
    #   # All the controllers are directly under the Bookshelf module
    #
    #   # GET '/' # => Bookshelf::DashboardController::Index
    #
    # @example Setting the value for a top level name structure
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         namespace Object
    #         controller_pattern "%{controller}Controller::%{action}"
    #
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #   end
    #
    #   module DashboardController
    #     include Bookshelf::Controller
    #
    #     action 'Index' do
    #       def call(params)
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.controller_pattern
    #     # => "%{controller}Controller::%{action}"
    #
    #   # All the controllers are at the top level namespace
    #
    #   # GET '/' # => DashboardController::Index
    def controller_pattern(value = nil)
      if value
        @controller_pattern = value
      else
        @controller_pattern ||= 'Controllers::%{controller}::%{action}'
      end
    end

    # Defines a relative pattern to find views:.
    #
    # Lotus supports multiple architectures (aka application structures), this
    # setting helps to understand the namespace where to find applications'
    # views:.
    #
    # By default this equals to `"Views::%{controller}::%{action}"`
    # That means views must be structured like this:
    # `Bookshelf::Views::Dashboard::Index`, where `Bookshelf` is the
    # application module, `Views` is the first value specified in the
    # pattern, `Dashboard` a module corresponding to the controller name
    # and `Index` the view, corresponding to the action name.
    #
    # This pattern MUST always contain `"%{controller}"` and `%{action}`.
    # This pattern SHOULD be used accordingly to `#controller_pattern` value.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload view_pattern(value)
    #   Sets the given value
    #   @param value [String] the view pattern
    #
    # @overload controller_pattern
    #   Gets the value
    #   @return [String]
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration#controller_pattern
    #
    # @example Getting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #
    #     module Views
    #       module Dashboard
    #         class Index
    #           include Bookshelf::View
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.view_pattern
    #     # => "Views::%{controller}::%{action}"
    #
    #   # All the views MUST live under Bookshelf::Views
    #
    #   # GET '/' # => Bookshelf::Views::Dashboard::Index
    #
    # @example Setting the value
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         view_pattern "%{controller}::%{action}"
    #
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #
    #     module Dashboard
    #       class Index
    #         include Bookshelf::View
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.view_pattern
    #     # => "%{controller}::%{action}"
    #
    #   # All the views are directly under the Bookshelf module
    #
    #   # GET '/' # => Bookshelf::Dashboard::Index
    #
    # @example Setting the value for a top level name structure
    #   require 'lotus'
    #
    #   module Bookshelf
    #     class Application < Lotus::Application
    #       configure do
    #         namespace Object
    #         view_pattern "%{controller}::%{action}"
    #
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #   end
    #
    #   module Dashboard
    #     class Index
    #       include Bookshelf::View
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.view_pattern
    #     # => "%{controller}::%{action}"
    #
    #   # All the views: are at the top level namespace
    #
    #   # GET '/' # => Dashboard::Index
    def view_pattern(value = nil)
      if value
        @view_pattern = value
      else
        @view_pattern ||= 'Views::%{controller}::%{action}'
      end
    end
  end
end
