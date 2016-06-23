require 'thread'
require 'rack/builder'
require 'hanami/router'

module Hanami
  class Container
    class Mounting
      def self.load!(&blk)
        new.instance_exec(&blk)
      end

      def mount(app, options)
        app.configuration.path_prefix options.fetch(:at) if hanami_app?(app)
      end

      private

      def hanami_app?(app)
        app.ancestors.include? Hanami::Application
      end

      def method_missing(m, *args)
      end
    end

    LOCK = Mutex.new

    attr_reader :routes

    def self.configure(options = {}, &blk)
      LOCK.synchronize do
        @@options       = options
        @@configuration = blk

        Mounting.load!(&blk)
      end
    end

    def initialize
      LOCK.synchronize do
        assert_configuration_presence!
        prepare_middleware_stack!
      end
    end

    def call(env)
      @builder.call(env)
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
      @builder.use Rack::MethodOverride

      @builder.run @routes
    end
  end
end
