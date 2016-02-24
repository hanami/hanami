require 'hanami/utils/kernel'
require 'hanami/utils/deprecation'
require 'hanami/environment'
require 'hanami/config/configure'
require 'hanami/config/cookies'
require 'hanami/config/framework_configuration'
require 'hanami/config/load_paths'
require 'hanami/config/logger'
require 'hanami/config/mapping'
require 'hanami/config/routes'
require 'hanami/config/security'
require 'hanami/config/sessions'

module Hanami
  # Configuration for a Hanami application
  #
  # @since 0.1.0
  class Configuration
    # @since 0.2.0
    # @api private
    #
    # @see Hanami::Configuration#ssl?
    SSL_SCHEME = 'https'.freeze

    # Initialize a new configuration instance
    #
    # @return [Hanami::Configuration]
    #
    # @since 0.1.0
    # @api private
    def initialize
      @blk = Proc.new{}
      @env = Environment.new
      @configurations = Hash.new { |k, v| k[v] = [] }
    end

    # Set a block yield when the configuration will be loaded or
    # set a path for the specific environment.
    #
    # @param environment [Symbol,nil] the configuration environment name
    # @param blk [Proc] the configuration block
    #
    # @return [self]
    #
    # @since 0.1.0
    # @api private
    def configure(environment = nil, path = nil, &blk)
      if environment && path
        @configurations[environment.to_s] << Config::Configure.new(root, path, &blk)
      elsif environment
        @configurations[environment.to_s] << blk
      else
        @blk = blk
      end

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
      evaluate_configurations!

      self
    end

    # Returns the security policy
    #
    # @return [Hanami::Config::Security]
    #
    # @since 0.3.0
    #
    # @see Hanami::Config::Security
    #
    # @example Getting values
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         security.x_frame_options         "ALLOW ALL"
    #         security.content_security_policy "script-src 'self' https://apis.example.com"
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.security.x_frame_options         # => "ALLOW ALL"
    #   Bookshelf::Application.configuration.security.content_security_policy # => "script-src 'self' https://apis.example.com"
    #
    # @example Setting values
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         security.x_frame_options         "ALLOW ALL"
    #         security.content_security_policy "script-src 'self' https://apis.example.com"
    #       end
    #     end
    #   end
    def security
      @security ||= Config::Security.new
    end

    # Force ssl redirection if http scheme is set
    #
    # @return [Boolean]
    #
    # @since 0.4.0
    #
    # @see Hanami::Routing::ForceSsl
    def force_ssl(value = nil)
      if value
        @force_ssl = value
      else
        @force_ssl || false
      end
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.root # => #<Pathname:/path/to/root>
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    # Hanami applications are namespaced: all the controllers and views live
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.namespace # => Bookshelf
    #
    #   # It will lookup namespaced controllers under Bookshelf
    #   # eg. Bookshelf::Controllers::Dashboard
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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

    # A Hanami::Layout for this application
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
    # @see http://rdoc.info/gems/hanami-view/Hanami/Layout
    # @see http://rdoc.info/gems/hanami-view/Hanami/View/Configuration:layout
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.layout # => nil
    #
    #   # All the views will render without a layout
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #     # => Hanami::View::Rendering::NullLayout
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
    # @see Hanami::Configuration#root
    # @see http://rdoc.info/gems/hanami-view/Hanami/View/Configuration:root
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.templates
    #     # => #<Pathname:/root/path>
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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

    # The application will serve the static assets under these directories.
    #
    # By default it's equal to the `public/` directory under the application
    # `root`.
    #
    # Otherwise, you can add differents relatives paths under `root`.
    #
    # @overload assets
    #   Gets the value
    #   @return [Hanami::Config::Assets] assets root
    #
    # @since 0.1.0
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.assets
    #     # => #<Pathname:/root/path/public>
    #
    # @example Adding new assets paths
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         assets do
    #           sources << [
    #             'vendor/assets'
    #           ]
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.assets
    #     # => #<Hanami::Config::Assets @root=#<Pathname:/root/path/assets>, @paths=["public"]>
    def assets(&blk)
      if @assets
        @assets.__add(&blk)
      else
        @assets ||= Config::FrameworkConfiguration.new(&blk)
      end
    end

    # Configure cookies
    # Enable cookies (disabled by default).
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload cookies(options)
    #   Sets the given value with their options.
    #   @param options [Hash, TrueClass, FalseClass]
    #
    # @overload cookies
    #   Gets the value.
    #   @return [Hanami::Config::Cookies]
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.cookies
    #     # => #<Hanami::Config::Cookies:0x0000000329f880 @options={}, @default_options={:httponly=>true, :secure=>false}>
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         cookies domain: 'hanamirb.org'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.cookies
    #     # => #<Hanami::Config::Cookies:0x0000000329f880 @options={:domain=>'hanamirb.org'}, @default_options={:domain=>'hanamirb.org', :httponly=>true, :secure=>false}>
    def cookies(options = nil)
      if options.nil?
        @cookies ||= Config::Cookies.new(self, options)
      else
        @cookies = Config::Cookies.new(self, options)
      end
    end

    # Configure sessions
    # Enable sessions (disabled by default).
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # Given Class as adapter it will be used as sessions middleware.
    # Given String as adapter it will be resolved as class name and used as
    # sessions middleware.
    # Given Symbol as adapter it is assumed it's name of the class under
    # Rack::Session namespace that will be used as sessions middleware
    # (e.g. :cookie for Rack::Session::Cookie).
    #
    # By default options include domain inferred from host configuration, and
    # secure flag inferred from scheme configuration.
    #
    # @overload sessions(adapter, options)
    #   Sets the given value.
    #   @param adapter [Class, String, Symbol] Rack middleware for sessions management
    #   @param options [Hash] options to pass to sessions middleware
    #
    # @overload sessions(false)
    #   Disables sessions
    #
    # @overload sessions
    #   Gets the value.
    #   @return [Hanami::Config::Sessions] sessions configuration
    #
    # @since 0.2.0
    #
    # @see Hanami::Configuration#host
    # @see Hanami::Configuration#scheme
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.sessions
    #     # => #<Hanami::Config::Sessions:0x00000001ca0c28 @enabled=false>
    #
    # @example Setting the value with symbol
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         sessions :cookie, secret: 'abc123'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.sessions
    #     # => #<Hanami::Config::Sessions:0x00000001589458 @enabled=true, @adapter=:cookie, @options={:domain=>"localhost", :secure=>false}>
    #
    # @example Disabling previusly enabled sessions
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         sessions :cookie
    #         sessions false
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.sessions
    #     # => #<Hanami::Config::Sessions:0x00000002460d78 @enabled=false>
    #
    def sessions(adapter = nil, options = {})
      if adapter.nil?
        @sessions ||= Config::Sessions.new
      else
        @sessions = Config::Sessions.new(adapter, options, self)
      end
    end

    # Application load paths
    # The application will recursively load all the Ruby files under these paths.
    #
    # By default it's empty in order to allow developers to decide their own
    # app structure.
    #
    # @return [Hanami::Config::LoadPaths] a set of load paths
    #
    # @since 0.1.0
    #
    # @see Hanami::Configuration#root
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.load_paths
    #     # => #<Hanami::Config::LoadPaths:0x007ff4fa212310 @paths=[]>
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #     # => #<Hanami::Config::LoadPaths:0x007fe3a20b18e0 @paths=[["app/controllers", "app/views"]]>
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
    #   @return [Hanami::Config::Routes] the set of routes
    #
    # @since 0.1.0
    #
    # @see http://rdoc.info/gems/hanami-router/Hanami/Router
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.routes
    #     # => nil
    #
    # @example Setting the value, by passing a block
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #     # => #<Hanami::Config::Routes:0x007ff50a991388 @blk=#<Proc:0x007ff50a991338@(irb):4>, @path=#<Pathname:.>>
    #
    # @example Setting the value, by passing a relative path
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         routes 'config/routes'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.routes
    #     # => #<Hanami::Config::Routes:0x007ff50a991388 @blk=nil, @path=#<Pathname:config/routes.rb>>
    def routes(path = nil, &blk)
      if path or block_given?
        @routes = Config::Routes.new(root, path, &blk)
      else
        @routes
      end
    end

    # Body parsing configuration.
    #
    # Specify a set of parsers for specific mime types that your application will use. This method will
    # return the application's parsers which you can use to add existing and new custom parsers for your
    # application to use.
    #
    # By default it's an empty `Array`
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload body_parsers(parsers)
    #   Specify a set of body parsers.
    #   @param parsers [Array] the body parser definitions
    #
    # @overload body_parsers
    #   Gets the value
    #   @return [Array] the set of parsers
    #
    # @since 0.2.0
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.body_parsers
    #     # => []
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         body_parsers :json, XmlParser.new
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.body_parsers
    #     # => [:json, XmlParser.new]
    #
    # @example Setting a new value after one is set.
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         body_parsers :json
    #         body_parsers XmlParser.new
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.body_parsers
    #     # => [XmlParser.new]
    #
    def body_parsers(*parsers)
      if parsers.empty?
        @body_parsers ||= []
      else
        @body_parsers = parsers
      end
    end

    # Application middleware.
    #
    # Specify middleware that your application will use. This method will return
    # the application's underlying Middleware stack which you can use to add new
    # middleware for your application to use. By default, the middleware stack
    # will contain only `Rack::Static` and `Rack::MethodOverride`. However, if
    # `assets false` was specified # in the configuration block, the default
    # `Rack::Static` will be removed.
    #
    # @since 0.2.0
    #
    # @see http://rdoc.info/gems/rack/Rack/Static
    # @see Hanami::Middleware#use
    #
    # @example
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         middleware.use Rack::MethodOverride, nil, 'max-age=0, private, must-revalidate'
    #         middleware.use Rack::ETag
    #       end
    #     end
    #   end
    def middleware
      @middleware ||= Hanami::Middleware.new(self)
    end

    # Application collection mapping.
    #
    # Specify a set of collections for the application, by passing a block, or a
    # relative path where to find the file that describes them.
    #
    # By default it's `nil`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload mapping(blk)
    #   Specify a set of mapping in the given block
    #   @param blk [Proc] the mapping definitions
    #
    # @overload mapping(path)
    #   Specify a relative path where to find the mapping file
    #   @param path [String] the relative path
    #
    # @overload mapping
    #   Gets the value
    #   @return [Hanami::Config::Mapping] the set of mappings
    #
    # @since 0.2.0
    #
    # @see http://rdoc.info/gems/hanami-model/Hanami/Mapper
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.mapping
    #     # => nil
    #
    # @example Setting the value, by passing a block
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         mapping do
    #           collection :users do
    #             entity User
    #
    #             attribute :id,   Integer
    #             attribute :name, String
    #           end
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.mapping
    #     # => #<Hanami::Config::Mapping:0x007ff50a991388 @blk=#<Proc:0x007ff123991338@(irb):4>, @path=#<Pathname:.>>
    #
    # @example Setting the value, by passing a relative path
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         mapping 'config/mapping'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.mapping
    #     # => #<Hanami::Config::Routes:0x007ff50a991388 @blk=nil, @path=#<Pathname:config/mapping.rb>>
    def mapping(path = nil, &blk)
      if path or block_given?
        @mapping = Config::Mapping.new(root, path, &blk)
      else
        @mapping
      end
    end

    # Adapter configuration.
    # The application will instantiate adapter instance based on this configuration.
    #
    # The given options must have key pairs :type and :uri
    # If it isn't, at the runtime the framework will raise a
    # `ArgumentError`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload adapter(options)
    #   Sets the given type and uri
    #   @param options [Hash] a set of options for adapter
    #
    # @overload adapter
    #   Gets the value
    #   @return [Hash] adapter options
    #
    # @since 0.2.0
    #
    # @see Hanami::Configuration#adapter
    # @see http://rdoc.info/gems/hanami-model/Hanami/Model/Configuration:adapter
    #
    # @example
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         adapter type: :sql, uri: 'sqlite3://uri'
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.adapter
    #     # => {type: :sql, uri: 'sqlite3://uri'}
    def adapter(options = {})
      if !options.empty?
        @adapter = options
      else
        @adapter
      end
    end

    # Set a format as default fallback for all the requests without a strict
    # requirement for the mime type.
    #
    # The given format must be coercible to a symbol, and be a valid mime type
    # alias. If it isn't, at the runtime the framework will raise a
    # `Hanami::Controller::UnknownFormatError`.
    #
    # By default this value is `:html`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload default_request_format(format)
    #   Sets the given value
    #   @param format [#to_sym] the symbol format
    #   @raise [TypeError] if it cannot be coerced to a symbol
    #
    # @overload default_request_format
    #   Gets the value
    #   @return [Symbol]
    #
    # @since 0.5.0
    #
    # @see http://rdoc.info/gems/hanami-controller/Hanami/Controller/Configuration#default_request_format
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.default_request_format # => :html
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         default_request_format :json
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.default_request_format # => :json
    def default_request_format(format = nil)
      if format
        @default_request_format = Utils::Kernel.Symbol(format)
      else
        @default_request_format || :html
      end
    end

    # Set a format to be used for all responses regardless of the request type.
    #
    # The given format must be coercible to a symbol, and be a valid mime type
    # alias. If it isn't, at the runtime the framework will raise a
    # `Hanami::Controller::UnknownFormatError`.
    #
    # By default this value is `:html`.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload default_response_format(format)
    #   Sets the given value
    #   @param format [#to_sym] the symbol format
    #   @raise [TypeError] if it cannot be coerced to a symbol
    #
    # @overload default_response_format
    #   Gets the value
    #   @return [Symbol,nil]
    #
    # @since 0.5.0
    #
    # @see http://rdoc.info/gems/hanami-controller/Hanami/Controller/Configuration#default_response_format
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.default_response_format # => :html
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         default_response_format :json
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.default_response_format # => :json
    def default_response_format(format = nil)
      if format
        @default_response_format = Utils::Kernel.Symbol(format)
      else
        @default_response_format
      end
    end

    # Set a format as default fallback for all the requests without a strict
    # requirement for the mime type.
    #
    # @since 0.1.0
    #
    # @deprecated Use {#default_request_format} instead.
    def default_format(format = nil)
      Hanami::Utils::Deprecation.new('default_format is deprecated, please use default_request_format')
      default_request_format(format)
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.scheme # => "http"
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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

    # Check if the application uses SSL
    #
    # @return [FalseClass,TrueClass] the result of the check
    #
    # @since 0.2.0
    #
    # @see Hanami::Configuration#scheme
    def ssl?
      scheme == SSL_SCHEME
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.host # => "localhost"
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    # By default this value is `2300`.
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.port # => 2300
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         port 8080
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Application.configuration.port # => 8080
    def port(value = nil)
      if value
        @port = Integer(value)
      else
        @port || @env.port
      end
    end

    # Defines a relative pattern to find controllers.
    #
    # Hanami supports multiple architectures (aka application structures), this
    # setting helps to understand the namespace where to find applications'
    # controllers and actions.
    #
    # By default this equals to <tt>"Controllers::%{controller}::%{action}"</tt>
    # That means controllers must be structured like this:
    # <tt>Bookshelf::Controllers::Dashboard::Index</tt>, where <tt>Bookshelf</tt>
    # is the application module, <tt>Controllers</tt> is the first value
    # specified in the pattern, <tt>Dashboard</tt> the controller and
    # <tt>Index</tt> the action.
    #
    # This pattern MUST always contain <tt>"%{controller}"</tt> and <tt>%{action}</tt>.
    # This pattern SHOULD be used accordingly to <tt>#view_pattern</tt> value.
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
    # @see Hanami::Configuration#view_pattern
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #     end
    #
    #     module Controllers::Dashboard
    #       class Index
    #         include Bookshelf::Action
    #
    #         def call(params)
    #           # ...
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #       class Index
    #         include Bookshelf::Action
    #
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #     class Index
    #       incude Bookshelf::Action
    #
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
    # Hanami supports multiple architectures (aka application structures), this
    # setting helps to understand the namespace where to find applications'
    # views:.
    #
    # By default this equals to <tt>"Views::%{controller}::%{action}"</tt>
    # That means views must be structured like this:
    # <tt>Bookshelf::Views::Dashboard::Index</tt>, where <tt>Bookshelf</tt> is
    # the application module, <tt>Views</tt> is the first value specified in the
    # pattern, <tt>Dashboard</tt> a module corresponding to the controller name
    # and <tt>Index</tt> the view, corresponding to the action name.
    #
    # This pattern MUST always contain <tt>"%{controller}"</tt> and <tt>%{action}</tt>.
    # This pattern SHOULD be used accordingly to <tt>#controller_pattern</tt> value.
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
    # @see Hanami::Configuration#controller_pattern
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
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

    # Decide if handle exceptions with an HTTP status or let them uncaught
    #
    # If this value is set to `true`, the configured exceptions will return
    # the specified HTTP status, the rest of them with `500`.
    #
    # If this value is set to `false`, the exceptions won't be caught.
    #
    # This is part of a DSL, for this reason when this method is called with
    # an argument, it will set the corresponding instance variable. When
    # called without, it will return the already set value, or the default.
    #
    # @overload handle_exceptions(value)
    #   Sets the given value
    #   @param value [TrueClass, FalseClass] true or false, default to true
    #
    # @overload handle_exceptions
    #   Gets the value
    #   @return [TrueClass, FalseClass]
    #
    # @since 0.2.0
    #
    # @see http://rdoc.info/gems/hanami-controller/Hanami/Controller/Configuration:handle_exceptions
    # @see http://httpstatus.es/500
    #
    # @example Enabled (default)
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           get '/error', to: 'error#index'
    #         end
    #       end
    #
    #       load!
    #     end
    #
    #     module Controllers::Error
    #       class Index
    #         include Bookshelf::Action
    #
    #         def call(params)
    #           raise ArgumentError
    #         end
    #       end
    #     end
    #   end
    #
    #   # GET '/error' # => 500 - Internal Server Error
    #
    # @example Disabled
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         handle_exceptions false
    #
    #         routes do
    #           get '/error', to: 'error#index'
    #         end
    #       end
    #
    #       load!
    #     end
    #
    #     module Controllers::Error
    #       class Index
    #         include Bookshelf::Action
    #
    #         def call(params)
    #           raise ArgumentError
    #         end
    #       end
    #     end
    #   end
    #
    #   # GET '/error' # => raises ArgumentError
    def handle_exceptions(value = nil)
      if value.nil?
        @handle_exceptions
      else
        @handle_exceptions = value
      end
    end

    # It lazily collects all the low level settings for Hanami::Model's
    # configuration and applies them when the application is loaded.
    #
    # NOTE: This forwards all the configurations to Hanami::Model, without
    # checking them. Before to use this feature, please have a look at the
    # current Hanami::Model version installed.
    #
    # NOTE: This may override some configurations of your application.
    #
    # @return [Hanami::Config::FrameworkConfiguration] the configuration
    #
    # @since 0.2.0
    #
    # @see http://www.rubydoc.info/gems/hanami-model/Hanami/Model/Configuration
    #
    # @example Define a setting
    #   require 'hanami'
    #   require 'hanami/model'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         model.adapter type: :memory, uri: 'memory://localhost/database'
    #       end
    #     end
    #   end
    #
    # @example Override a setting
    #   require 'hanami'
    #   require 'hanami/model'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         adapter       type: :sql,    uri: 'postgres://localhost/database'
    #         model.adapter type: :memory, uri: 'memory://localhost/database'
    #       end
    #     end
    #   end
    #
    #   # The memory adapter will override the SQL one
    def model
      @model ||= Config::FrameworkConfiguration.new
    end

    # It lazily collects all the low level settings for Hanami::Controller's
    # configuration and applies them when the application is loaded.
    #
    # NOTE: This forwards all the configurations to Hanami::Controller, without
    # checking them. Before to use this feature, please have a look at the
    # current Hanami::Controller version installed.
    #
    # NOTE: This may override some configurations of your application.
    #
    # @return [Hanami::Config::FrameworkConfiguration] the configuration
    #
    # @since 0.2.0
    #
    # @see http://www.rubydoc.info/gems/hanami-controller/Hanami/Controller/Configuration
    #
    # @example Define a setting
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         controller.default_request_format :json
    #       end
    #     end
    #   end
    #
    # @example Override a setting
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         handle_exceptions            false
    #         controller.handle_exceptions true
    #       end
    #     end
    #   end
    #
    #   # Exceptions will be handled
    def controller
      @controller ||= Config::FrameworkConfiguration.new
    end

    # It lazily collects all the low level settings for Hanami::View's
    # configuration and applies them when the application is loaded.
    #
    # NOTE: This forwards all the configurations to Hanami::View, without
    # checking them. Before to use this feature, please have a look at the
    # current Hanami::View version installed.
    #
    # NOTE: This may override some configurations of your application.
    #
    # @return [Hanami::Config::FrameworkConfiguration] the configuration
    #
    # @since 0.2.0
    #
    # @see http://www.rubydoc.info/gems/hanami-view/Hanami/View/Configuration
    #
    # @example Define a setting
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         view.layout :application
    #       end
    #     end
    #   end
    #
    # @example Override a setting
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         layout      :application
    #         view.layout :backend
    #       end
    #     end
    #   end
    #
    #   # It will use `:backend` layout
    def view
      @view ||= Config::FrameworkConfiguration.new
    end

    # Defines a Config::Logger instance to the logger configuration.
    #
    # This instance will be used to generate the hanami logger available on application module.
    #
    # @return [Config::Logger] Configure logger instance
    #
    # @since 0.5.0
    #
    # @example Define a logger
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         logger.stream 'path/to/log/file'
    #       end
    #       load!
    #     end
    #
    #     module Controllers::Error
    #       class Index
    #         include Bookshelf::Action
    #
    #         def call(params)
    #           Bookshelf::Logger.info "Logging to STDOUT"
    #         end
    #       end
    #     end
    #   end
    #
    def logger
      @logger ||= Config::Logger.new
    end

    # This options is used as a bridge between container and router application.
    #
    # @return [String, NilClass] path prefix for routes
    #
    # @since 0.4.0
    # @api private
    def path_prefix(value = nil)
      if value.nil?
        @path_prefix
      else
        @path_prefix = value
      end
    end

    private

    # @since 0.2.0
    # @api private
    def evaluate_configurations!
      configurations.each { |c| instance_eval(&c) }
    end

    # @since 0.2.0
    # @api private
    def configurations
      [ @blk ] + @configurations[@env.environment]
    end
  end
end
