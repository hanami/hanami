require 'thread'
require 'rack/builder'
require 'lotus/router'

module Lotus
  class Container
    class Router < ::Lotus::Router
      def mount(app, options)
        app = app.new(path_prefix: options.fetch(:at)) if lotus_app?(app)
        super(app, options)
      end

      private

      def lotus_app?(app)
        app.ancestors.include? Lotus::Application
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

      if Lotus.environment.serve_static_assets?
        require 'lotus/static'
        @builder.use Lotus::Static
      end

      @builder.run @routes
    end
  end
end
