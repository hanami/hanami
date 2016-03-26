require 'thread'
require 'rack/builder'
require 'hanami/router'

module Hanami
  class Container
    class Router < ::Hanami::Router
      def mount(app, options)
        app = app.new(path_prefix: options.fetch(:at)) if hanami_app?(app)
        super(app, options)
      end

      private

      def hanami_app?(app)
        app.ancestors.include? Hanami::Application
      end
    end

    attr_reader :routes

    def self.configure(options = {}, &blk)
      Mutex.new.synchronize do
        @@options       = options
        @@configuration = blk
      end
    end

    def initialize
      Mutex.new.synchronize do
        assert_configuration_presence!
        prepare_middleware_stack!
        load_initializers!
      end
    end

    def call(env)
      @builder.call(env)
    end

    # The root of the container
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
    # @since x.x.x
    #
    # @see http://www.ruby-doc.org/core-2.1.2/Dir.html#method-c-pwd
    #
    # @example Getting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Container < Hanami::Container
    #     end
    #   end
    #
    #   Bookshelf::Container.root # => #<Pathname:/path/to/root>
    #
    # @example Setting the value
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Container < Hanami::Container
    #       root '/path/to/another/root'
    #     end
    #   end
    def self.root(value = nil)
      if value
        @@root = value
      else
        Utils::Kernel.Pathname(@@root || Dir.pwd).realpath
      end
    end

    def root(value = nil)
      self.class.root(value)
    end

    private
    def assert_configuration_presence!
      unless self.class.class_variable_defined?(:@@configuration)
        raise ArgumentError.new("#{ self.class } doesn't have any application mounted.")
      end
    end

    def prepare_middleware_stack!
      @builder = ::Rack::Builder.new
      @routes  = Router.new(&@@configuration)

      if Hanami.environment.serve_static_assets?
        require 'hanami/static'
        @builder.use Hanami::Static
      end

      @builder.run @routes
    end

    def load_initializers!
      Dir["#{self.root}/config/initializers/**/*.rb"].each do |file|
        require file
      end
    end
  end
end
