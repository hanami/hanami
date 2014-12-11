require 'thread'
require 'lotus/router'

module Lotus
  class Container
    attr_reader :routes

    def self.configure(&blk)
      Mutex.new.synchronize { @@configuration = blk }
    end

    def initialize
      Mutex.new.synchronize do
        assert_configuration_presence!
        @routes = Lotus::Router.new(&@@configuration)
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
