require 'thread'
require 'lotus/router'

module Lotus
  class Container
    class Router < ::Lotus::Router
      def mount(app, options)
        if lotus_app?(app)
          app = app.new(path_prefix: options.fetch(:at))
        end
        super(app, options)
      end

      private

      def lotus_app?(app)
        app.ancestors.include? Lotus::Application
      end
    end

    attr_reader :routes

    def self.configure(&blk)
      Mutex.new.synchronize { @@configuration = blk }
    end

    def initialize
      Mutex.new.synchronize do
        assert_configuration_presence!
        @routes = Router.new(&@@configuration)
      end
    end

    def call(env)
      @routes.call(env)
    end

    private
    def assert_configuration_presence!
      unless self.class.class_variable_defined?(:@@configuration)
        raise ArgumentError.new("#{ self.class } doesn't have any application mounted.")
      end
    end
  end
end
